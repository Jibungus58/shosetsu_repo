-- {"id":11151412,"ver":"1.0.6","libVer":"1.0.0","author":"me","repo":"novel-bin"}

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
local function extractNovel(row)
	local a = row:selectFirst("h4 a, h3 a, .title a, .novel-title a, a[href*='/novel-bin/']")

	if not a then return nil end

	local href = a:attr("href")
	local title = a:text()

	local img = row:selectFirst("img")
	local imageURL = ""

	if img then
		imageURL =
			img:attr("data-src") ~= "" and img:attr("data-src")
			or img:attr("src")
	end

	if imageURL and imageURL:sub(1,1) == "/" then
		imageURL = baseURL:gsub("/$", "") .. imageURL
	end

	return Novel({
		title = title,
		link = shrinkURL(href),
		imageURL = imageURL
	})
end
local function hot(data)
	local doc = GETDocument(baseURL .. "allvisit/?page=")
	local container = doc:selectFirst(".list.list-novel.col-xs-12")
	if not container then return {} end

	local rows = container:select(".row")
	local novels = {}

	for i = 0, rows:size() - 1 do
		local n = extractNovel(rows:get(i))
		if n then
			table.insert(novels, n)
		end
	end

	return novels
end
local function search(data)
	local doc = GETDocument(baseURL .. "search?keyword=" .. data[QUERY])

	local container = doc:selectFirst(".list.list-novel.col-xs-12")
	if not container then return {} end

	local rows = container:select(".row")
	local novels = {}

	for i = 0, rows:size() - 1 do
		local n = extractNovel(rows:get(i))
		if n then
			table.insert(novels, n)
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
	Listing("Hot", false, hot),
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