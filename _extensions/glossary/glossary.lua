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
      options_contents_as_inlines = options.contents
      quarto.log.output("Selected contents are: ", options.contents)
      options_contents = {}
      --string_match = {}
      for _,filename in ipairs(options_contents_as_inlines) do
        options_contents[#options_contents + 1] = filename[1].text
      --  string_match[#string_match + 1] = string.match(filename[1].text, globtopattern("*2.qmd"))      
      end
      quarto.log.output("Selected filepaths are: ", options_contents)
      f_list = {}
      for dir in io.popen("find . -type f -not -path '*/.*'"):lines() do
        f_list[#f_list + 1] = string.match(dir, globtopattern("*.qmd"))
      end
      quarto.log.output("here are the files that were matched to the glob: ", f_list)
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
      quarto.log.output("the current filename is: ", filename)
      local filepath = current_dir .. "/" .. filename
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

function globtopattern(g)
  -- Some useful references:
  -- - apr_fnmatch in Apache APR.  For example,
  --   http://apr.apache.org/docs/apr/1.3/group__apr__fnmatch.html
  --   which cites POSIX 1003.2-1992, section B.6.

  local p = "^"  -- pattern being built
  local i = 0    -- index in g
  local c        -- char at index i in g.

  -- unescape glob char
  local function unescape()
    if c == '\\' then
      i = i + 1; c = g:sub(i,i)
      if c == '' then
        p = '[^]'
        return false
      end
    end
    return true
  end

  -- escape pattern char
  local function escape(c)
    return c:match("^%w$") and c or '%' .. c
  end

  -- Convert tokens at end of charset.
  local function charset_end()
    while 1 do
      if c == '' then
        p = '[^]'
        return false
      elseif c == ']' then
        p = p .. ']'
        break
      else
        if not unescape() then break end
        local c1 = c
        i = i + 1; c = g:sub(i,i)
        if c == '' then
          p = '[^]'
          return false
        elseif c == '-' then
          i = i + 1; c = g:sub(i,i)
          if c == '' then
            p = '[^]'
            return false
          elseif c == ']' then
            p = p .. escape(c1) .. '%-]'
            break
          else
            if not unescape() then break end
            p = p .. escape(c1) .. '-' .. escape(c)
          end
        elseif c == ']' then
          p = p .. escape(c1) .. ']'
          break
        else
          p = p .. escape(c1)
          i = i - 1 -- put back
        end
      end
      i = i + 1; c = g:sub(i,i)
    end
    return true
  end

  -- Convert tokens in charset.
  local function charset()
    i = i + 1; c = g:sub(i,i)
    if c == '' or c == ']' then
      p = '[^]'
      return false
    elseif c == '^' or c == '!' then
      i = i + 1; c = g:sub(i,i)
      if c == ']' then
        -- ignored
      else
        p = p .. '[^'
        if not charset_end() then return false end
      end
    else
      p = p .. '['
      if not charset_end() then return false end
    end
    return true
  end

  -- Convert tokens.
  while 1 do
    i = i + 1; c = g:sub(i,i)
    if c == '' then
      p = p .. '$'
      break
    elseif c == '?' then
      p = p .. '.'
    elseif c == '*' then
      p = p .. '.*'
    elseif c == '[' then
      if not charset() then break end
    elseif c == '\\' then
      i = i + 1; c = g:sub(i,i)
      if c == '' then
        p = p .. '\\$'
        break
      end
      p = p .. escape(c)
    else
      p = p .. escape(c)
    end
  end
  return p
end




return{
  {Meta = read_meta},
  {Div = insert_glossary}
}