local options_class = nil
quarto.log.output("=== Class Name ===")


-- permitted options include:
-- glossary:
--   class: none | class
function Meta(meta)
  local options = meta["glossary"]
  if options.class ~= nil then
      options_class = options.class[1].text
  end
end

function Pandoc(el)
  local current_dir = pandoc.path.directory(PANDOC_SCRIPT_FILE)
  local filepath = current_dir .. "/" .. "notes.qmd"
  local file_contents = pandoc.read(io.open(filepath):read "*a", "markdown", PANDOC_READER_OPTIONS).blocks
  local filtered_blocks = {}
  for _, block in ipairs(file_contents) do
    if (block.t == "Div" and block.classes:includes(options_class))  then
      table.insert(filtered_blocks, block)  -- Add the block to the filtered table
    end
  end
  el.blocks:extend(filtered_blocks)
  return el
end


function replace_with_glossary(div)

return{
  Div = replace_with_glossary
}