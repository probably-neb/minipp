-- Function to split a string by a delimiter
local function split(str, delimiter)
  local result = {}
  for match in (str..delimiter):gmatch("(.-)"..delimiter) do
    table.insert(result, match)
  end
  return result
end

-- Function to convert CSV data to Pandoc table
local function csv_to_table(csv_data)
  local rows = {}
  for row in csv_data:gmatch("[^\r\n]+") do
    table.insert(rows, split(row, ","))
  end

  local cells = {}
  for i, row in ipairs(rows) do
    local row_cells = {}
    for j, value in ipairs(row) do
      table.insert(row_cells, pandoc.Cell(pandoc.Plain{pandoc.Str(value)}))
    end
    table.insert(cells, pandoc.Row(row_cells))
  end

  local headers = cells[1]
  table.remove(cells, 1)
  local head = {rows = headers}
  local body = {body = cells}
  return pandoc.Table(head, body, pandoc.Attr(), pandoc.Attr())
end

-- Register filter function
function CodeBlock(el)
  -- Check if the element is a CodeBlock with class "csv"
  if el.t == 'CodeBlock' and el.attr.classes:includes('csv') then
    -- Get the CSV data from the code block contents
   local filepath = el.text
   local file = io.open(filepath, 'r')
   local contents = file:read('*a')
   file:close()
    -- Convert CSV data to Pandoc table
    return csv_to_table(contents)
  end
end
