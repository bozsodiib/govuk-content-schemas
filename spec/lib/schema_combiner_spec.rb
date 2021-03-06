require 'govuk_content_schemas/schema_combiner'

RSpec.describe GovukContentSchemas::SchemaCombiner do
  let(:metadata_schema) { build_schema('metadata.json', properties: build_string_properties('body')) }
  let(:format_name) { 'my_format' }
  subject(:combined) { described_class.new(metadata_schema, format_name, details_schema: details_schema).combined }

  context "combining a simple metadata and details schema" do
    let(:details_schema) { build_schema('details.json', properties: build_string_properties('detail')) }

    it 'adds a details property to the combined schema' do
      expect(combined.schema['properties']['details']).to be_a(Hash)
    end

    it 'explicitly defines the format name in the format property' do
      expect(combined.schema['properties']['format']).to eq(
        {
          "type" => "string",
          "enum" => [format_name]
        }
      )
    end

    it 'strips the $schema key from the embedded details property' do
      expect(combined.schema['properties']['details']).not_to have_key('$schema')
    end

    it 'embeds the remaining content of the details schema as the details property definition' do
      remaining_content_of_details_schema = details_schema.schema.reject { |k, v| k == '$schema'}
      expect(combined.schema['properties']['details']).to eq(remaining_content_of_details_schema)
    end

    it 'uses the original uri for the combined schema' do
      expect(combined.uri).to eq(metadata_schema.uri)
    end
  end

  context "combining schemas which have definitions" do
    let(:metadata_schema) {
      build_schema('metadata.json',
        properties: build_string_properties('body'),
        definitions: build_string_properties('def1')
      )
    }

    let(:details_schema) {
      build_schema('details.json',
        properties: build_string_properties('detail'),
        definitions: build_string_properties('def2')
      )
    }

    it 'removes the definitions from the embedded details property' do
      expect(combined.schema['properties']['details']).not_to have_key('definitions')
    end

    it 'merges the definitions from the details schema into the top-level definitions' do
      expect(combined.schema['definitions']).to include('def1', 'def2')
      expect(combined.schema['definitions']['def2']).to eq(details_schema.schema['definitions']['def2'])
    end
  end

  context "combining a metadata schema and a links schema" do
    let(:links_schema) {
      build_schema('links.json',
        properties: build_string_properties('lead_organisations'),
        definitions: build_string_properties('guid_list')
      )
    }
    subject(:combined) { described_class.new(metadata_schema, format_name, links_schema: links_schema).combined }

    it 'adds a links property to the combined schema' do
      expect(combined.schema['properties']['links']).to be_a(Hash)
    end

    it 'strips the $schema key from the embedded links property' do
      expect(combined.schema['properties']['links']).not_to have_key('$schema')
    end

    it 'embeds the remaining content of the links schema as the links property definition' do
      remaining_content_of_links_schema = links_schema.schema.reject { |k, v| %w{$schema definitions}.include?(k) }
      expect(combined.schema['properties']['links']).to eq(remaining_content_of_links_schema)
    end

    it 'merges the definitions from the links schema into the combined schemas definitions' do
      expect(combined.schema['definitions']).to include('guid_list')
      expect(combined.schema['definitions']['guid_list']).to eq(links_schema.schema['definitions']['guid_list'])
    end
  end
end
