-- {"id":11151412,"ver":"1.0.4","libVer":"1.0.0","author":"me","repo":"novel-bin"}

local baseURL = "https://novel-bin.net/"

local function shrinkURL(url)
	return url:gsub("^https://novel%-bin%.net/", "")
end

local function expandURL(url)
	if url:match("^https?://") then
		return url
	end

	return baseURL .. url
end
-- HOT LIST
local function hot(data)
	local doc = GETDocument(baseURL .. "allvisit/")

	local container = doc:selectFirst(".list.list-novel.col-xs-12")
	if not container then return {} end

	local rows = container:select(".row")
	local novels = {}

	for i = 0, rows:size() - 1 do
		local row = rows:get(i)

		-- EXCLUDE genre blocks
		if not row:selectFirst(".list-genre") then
			local a = row:selectFirst("a")
            local img = row:selectFirst("img")

            local imageURL = ""
            
            if img then
                imageURL = img:attr("src")
            
                if imageURL:sub(1, 1) == "/" then
                    imageURL = baseURL:gsub("/$", "") .. imageURL
                end
            end

			if a then
				table.insert(novels, Novel({
					title = a:text() .. " | " .. imageURL,
					link = shrinkURL(a:attr("href")),
					imageURL = imageUrl
				}))
			end
		end
	end

	return novels
end
-- SEARCH
local function search(data)
	local doc = GETDocument(baseURL .. "search?keyword=" .. data[QUERY])

	local container = doc:selectFirst(".list.list-novel.col-xs-12")
	if not container then return {} end

	local rows = container:select(".row")
	local novels = {}

	for i = 0, rows:size() - 1 do
		local row = rows:get(i)

		if not row:selectFirst(".list-genre") then
			local a = row:selectFirst("a")
            local img = row:selectFirst("img")

            local imageURL = ""
            
            if img then
                imageURL = img:attr("src")
            
                if imageURL:sub(1, 1) == "/" then
                    imageURL = baseURL:gsub("/$", "") .. imageURL
                end
            end

			if a then
				table.insert(novels, Novel({
					title = a:text() .. " | " .. imageURL,
					link = shrinkURL(a:attr("href")),
					imageURL = imageURL
				}))
			end
		end
	end

	return novels
end

-- NOVEL PAGE
local function parseNovel(novelURL)
	local url = expandURL(novelURL)
	local doc = GETDocument(url)

	local info = NovelInfo()

	info:setTitle((doc:selectFirst("h1") and doc:selectFirst("h1"):text()) or "Unknown")

	local author = doc:selectFirst(".author, .writer")
	if author then
		info:setAuthor(author:text())
	end

	local desc = doc:selectFirst(".description, .summary, .novel-desc")
	if desc then
		info:setDescription(desc:text())
	end

    local chapters = {}

    local columns = doc:select(".col-xs-12.col-sm-4.col-md-4")
    
    for i = 0, columns:size() - 1 do
        local col = columns:get(i)
    
        local list = col:selectFirst("ul.list-chapter")
        if list then
            local items = list:select("li")
    
            for j = 0, items:size() - 1 do
                local li = items:get(j)
                local a = li:selectFirst("a")
    
                if a then
                    table.insert(chapters, NovelChapter({
                        title = a:text(),
                        link = shrinkURL(a:attr("href"))
                    }))
                end
            end
        end
    end

	info:setChapters(chapters)

	return info
end

-- CHAPTER PAGE
local function getPassage(chapterURL)
	local doc = GETDocument(expandURL(chapterURL))

	local content = doc:selectFirst("#chr-content")

	if content then
		return content:html()
	end

	return ""
end

-- LISTINGS
local listings = {
	Listing("Hot", true, hot),
}

return {
	id = 11151412,
	name = "novel-bin",
	baseURL = baseURL,

	listings = listings,
	search = search,
	hasSearch = true,
	isSearchIncrementing = true,

	parseNovel = parseNovel,
	getPassage = getPassage,

	shrinkURL = shrinkURL,
	expandURL = expandURL,
}