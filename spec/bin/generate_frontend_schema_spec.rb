require 'spec_helper'
require 'tmpdir'

require 'govuk_content_schemas/schema_combiner'
require 'govuk_content_schemas/frontend_schema_generator'

RSpec::Matchers.define :exist do
  match { |actual| actual.exist? }
end

RSpec.describe 'generate_frontend_schema' do
  let(:executable_path) {
    Pathname.new('../../bin/generate_frontend_schema').expand_path(File.dirname(__FILE__))
  }

  let(:tmpdir) { Pathname.new(Dir.mktmpdir) }

  let(:publisher_schema) {
    build_publisher_schema(%w{body details}, %{related})
  }
  let(:frontend_links_definition) {
    build_schema('frontend_links_definition.json', properties: build_string_properties('my_link_property'))
  }

  let(:publisher_schema_filename) {
    tmpdir + "publisher.json"
  }
  let(:frontend_schema_filename) {
    tmpdir + "frontend.json"
  }
  let(:frontend_links_definition_path) {
    tmpdir + "frontend_links_definition.json"
  }

  before(:each) {
    File.write(publisher_schema_filename, publisher_schema.to_s)
    File.write(frontend_links_definition_path, frontend_links_definition.to_s)
  }
  after(:each) { FileUtils.remove_entry_secure(tmpdir) }

  before(:each) do
    output = `#{executable_path} --frontend-links-definition="#{frontend_links_definition_path}" "#{publisher_schema_filename}" > "#{frontend_schema_filename}"`
    fail(output) unless $?.success?
    output
  end

  it "produces an frontend schema output file" do
    expect(frontend_schema_filename).to exist
  end

  specify "the frontend schema file contains a frontend schema" do
    reader = JSON::Schema::Reader.new(accept_file: true, accept_uri: false)
    actual = reader.read(frontend_schema_filename)
    expected = GovukContentSchemas::FrontendSchemaGenerator.new(publisher_schema, frontend_links_definition).generate

    expect(actual.schema).to eq(expected.schema)
  end
end
