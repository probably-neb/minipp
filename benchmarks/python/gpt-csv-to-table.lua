-- csv-to-table.lua

-- This function reads a file and returns its content as a string
function read_file(path)
    local file = io.open(path, "r")
    if not file then
        error("File not found: " .. path)
    end
    local content = file:read("*all")
    file:close()
    return content
end

-- This function parses a CSV string and returns a table of rows (each containing pandoc cells)
function parse_csv(csv_content)
    local rows = {}
    for line in csv_content:gmatch("[^\r\n]+") do
        local row = {}
        for value in line:gmatch("[^,]+") do
            -- Wrap the string value in a Cell containing a Plain block of text
            table.insert(row, pandoc.Cell(pandoc.Plain({pandoc.Str(value)})))
        end
        -- Insert the row into the rows table
        table.insert(rows, pandoc.Row(row))
    end
    return rows
end

-- Filter function for code blocks
function CodeBlock(block)
    if block.classes[1] == "csv" then
        local file_path = block.text
        local csv_content = read_file(file_path)
        local rows = parse_csv(csv_content)
        
        -- Assume the first row as headers and the rest as table body
        local headers = pandoc.Row(rows[1].cells)
        table.remove(rows, 1)  -- Remove the header row from the rows list

        -- Define alignments and widths for all columns, assuming default alignment and relative width
        local aligns = {}
        local widths = {}
        for i = 1, #headers.cells do
            table.insert(aligns, 'AlignDefault')
            table.insert(widths, 0)  -- Auto width
        end

        -- Create a pandoc caption
        -- local caption = {pandoc.Str("CSV Table: " .. file_path)}

        local head = pandoc.TableHead {rows = headers}
        -- Create and return the pandoc Table
        local tbl = pandoc.Table({}, {}, head, rows)
        return tbl
    end
end

return {
    { CodeBlock = CodeBlock }
}
