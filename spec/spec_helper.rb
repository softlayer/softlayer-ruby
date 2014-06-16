
require 'json'

def fixture_from_json(json_file_name)
	full_name = File.basename(json_file_name, ".json") + ".json"
	JSON.parse(File.read(File.join(File.dirname(__FILE__), "fixtures/#{full_name}")))
end