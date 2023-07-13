local options_class = "def"
local options_contents = nil

quarto.log.output("=== Preamble ===")

-- permitted options include:
-- glossary:
--   id: string
--   class: none | class
--   contents:
--     - "first-file.qmd"
--     - "second-file.qmd"
local function read_meta(meta)
  quarto.log.output("Reading meta . . .")
  local options = meta["glossary"]
  if options.class ~= nil then
      options_class = options.class[1].text
      quarto.log.output("Selected Class is: ", options_class)
  end
  if options.id ~= nil then
      options_id = options.id[1].text
      quarto.log.output("Selected id is: ", options_id)
  end
    if options.contents ~= nil then
      --options_contents = options.contents[1][1].text
      options_contents = options.contents
      quarto.log.output("Selected contents are: ", options.contents)
  end
end

-- Build list of filepaths to scan through
local current_dir = pandoc.path.directory(PANDOC_SCRIPT_FILE)

-- Open files as blocks

function insert_glossary(div)
  
  quarto.log.output("Inserting glossary . . .")
  quarto.log.output(div.identifier == options_id)
  local filtered_blocks = {}
  
  -- find a div it likes
  if (div.identifier == options_id) then
    -- read in files
    for _,filename in ipairs(options_contents) do
      quarto.log.output("the first filename is: ", filename[1].text)
      local filepath = current_dir .. "/" .. filename[1].text
      quarto.log.output("The filepath is", filepath)
      local file_contents = pandoc.read(io.open(filepath):read "*a", "markdown", PANDOC_READER_OPTIONS).blocks
      --read in contents of files
      for _, block in ipairs(file_contents) do
        local has_class = false
        if (block.classes ~= nil) then
          has_class = block.classes:includes(options_class)
        end
        if (block.t == "Div" and has_class) then
          table.insert(filtered_blocks, block)  -- Add the block to the filtered table
        end
      end
    end
    return filtered_blocks
  end
end

return{
  {Meta = read_meta},
  {Div = insert_glossary}
}