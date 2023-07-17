local options_class = "def"
local options_contents = nil

quarto.log.output("=== Output Log ===")

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
      quarto.log.output("Selected class is: ", options_class)
  end
  
  if options.id ~= nil then
      options_id = options.id[1].text
      quarto.log.output("Selected id is: ", options_id)
  end
  
  if options.contents ~= nil then
    files_added = {}
    files_to_scan = {}
    
    for g = 1,#options.contents do
      glob = options.contents[g][1].text
      if string.sub(glob, 1, 1) ~= "!" then -- add these files
        for f in io.popen("find . -type f -not -path '*/.*'"):lines() do
          quarto.log.output("File path: ", f)
          -- for full ignore use:
          -- find . -type f \( -not \( -path '*/.*' -o -path '*/_*' \) -o -name 'README.qmd' -o -name 'README.md' \) -prune -o -print
          glob_match = string.match(f, globtopattern(glob))
          if glob_match ~=nil and new_file(files_added, glob_match) then
            files_added[#files_added + 1] = glob_match
          end
        end
      else -- remove these files
        ignored_glob = string.sub(glob, 2)
        for i = 1,#files_added do
          if (string.match(files_added[i], globtopattern(ignored_glob)) == nil) then
            files_to_scan[#files_to_scan + 1] = files_added[i]
          end
        end
      end
    end
    
    if #files_to_scan == 0 then
      files_to_scan = files_added
    end

    quarto.log.output("Files to be scanned: ", files_to_scan)
  end
  
end

function new_file(list, element)
  out = true
  for i = 1, #list do
    if list[i] == element then
      out = false
      break 
    end
  end
  return out
end

    -- f_list = {}
    -- for f in file_list do -- for every file
    --   quarto.log.output("The f is:", f)
    --  for g = 1, #options.contents do -- for every glob
    --    quarto.log.output("glob is: ", options.contents[g][1].text)
    --    f_list[#f_list + 1] = string.match(f, globtopattern(options.contents[g][1].text))
    --  end
    --end


      
    --local function remove_duplicates(list)
    --    local res = {}
    --    local hash = {}
        
    --    for _,v in ipairs(list) do
    --      if (not hash[v]) then
    --        res[#res+1] = v
    --        hash[v] = true
    --      end
    --    end
        
    --    return res
    --  end

    --  f_list = remove_duplicates(f_list)


-- Build list of filepaths to scan through
--local current_dir = pandoc.path.directory(PANDOC_SCRIPT_FILE)

-- Open files as blocks

function insert_glossary(div)
  
  local filtered_blocks = {}
  
  -- find a div it likes
  if (div.identifier == options_id) then
    -- read in files
    for _,filename in ipairs(files_to_scan) do
      local file_contents = pandoc.read(io.open(filename):read "*a", "markdown", PANDOC_READER_OPTIONS).blocks
      --read in contents of files
      for _, block in ipairs(file_contents) do
        if (block.classes ~= nil and block.t == "Div" and block.classes:includes(options_class)) then
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