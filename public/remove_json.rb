Dir["*.json"].each do |filename|
  lines = IO.readlines(filename).map do |line|
    if line.include?("\"path\":") and line.include?(".json")
      line.slice! ".json"
      line
    end
    line
  end
  File.open(filename, 'w') do |file|
    file.puts lines
  end
end
