local options_class = "def"
quarto.log.output("=== Preamble ===")

-- permitted options include:
-- glossary:
--   class: none | class
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
end

-- Build list of filepaths to scan through
local current_dir = pandoc.path.directory(PANDOC_SCRIPT_FILE)
local filepath = current_dir .. "/" .. "notes.qmd"

-- Open files as blocks

function insert_glossary(div)
  
  quarto.log.output("Inserting glossary . . .")
  quarto.log.output(div.identifier == options_id)
  local filtered_blocks = {}
  
-- find a div it likes
  if (div.identifier == options_id) then
  -- read in files
  local file_contents = pandoc.read(io.open(filepath):read "*a", "markdown", PANDOC_READER_OPTIONS).blocks

    for _, block in ipairs(file_contents) do
      local has_class = false
      if (block.classes ~= nil) then
        has_class = block.classes:includes(options_class)
      end
      if (block.t == "Div" and has_class) then
        table.insert(filtered_blocks, block)  -- Add the block to the filtered table
      end
    end
    return filtered_blocks
  end
end

quarto.log.output("=== Walking the AST ===")

return{
  {Meta = read_meta},
  {Div = insert_glossary}
}