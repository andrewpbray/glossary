local options_class = nil
quarto.log.output("=== Class Name ===")


-- options include:
-- glossary:
--   class: none | class
local function read_meta(meta)
  local options = meta["glossary"]
  if options ~= nil then
    if options.class ~= nil then
      options_class = options.class
      quarto.log.output(meta)
    end
  end
end

local function isDef(class)
  return class == "def"
end

local function isClass(class)
  return class == options_class
end

function Pandoc(el)
  local current_dir = pandoc.path.directory(PANDOC_SCRIPT_FILE)
  local filepath = current_dir .. "/" .. "notes.qmd"
  local file_contents = pandoc.read(io.open(filepath):read "*a", "markdown", PANDOC_READER_OPTIONS).blocks
  local filtered_blocks = {}
  for _, block in ipairs(file_contents) do
    if (block.t == "Div" and block.attr.classes:find_if(isDef))  then
      table.insert(filtered_blocks, block)  -- Add the block to the filtered table
    end
  end
  el.blocks:extend(filtered_blocks)
  return el
end