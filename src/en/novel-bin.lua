-- {"id":11151412,"ver":"1.0.1","libVer":"1.0.0","author":"me","repo":"novel-bin"}

local baseURL = "https://novel-bin.net/"

local function shrinkURL(url)
	return url:gsub(baseURL, "")
end

local function expandURL(url)
	return baseURL .. url
end

local function debugList(doc)
	local nodes = doc:select("a")
	local novels = {}

	for i = 0, nodes:size() - 1 do
		local a = nodes:get(i)

		local href = a:attr("href")
		local title = a:text()

		if href and href:find("/novel-bin/") then
			table.insert(novels, Novel({
				title = title,
				link = shrinkURL(href)
			}))
		end
	end

	return novels
end
local function hot(data)
	local doc = GETDocument(baseURL .. "allvisit/")
	return debugList(doc)
end
local function search(data)
	local doc = GETDocument(baseURL .. "search?keyword=" .. data[QUERY])
	return debugList(doc)
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

	for _, v in ipairs(doc:select(".chapter-list a, .chapters a, .chapter-item a")) do
		table.insert(chapters, NovelChapter({
			title = v:text(),
			link = shrinkURL(v:attr("href"))
		}))
	end

	info:setChapters(chapters)

	return info
end

-- CHAPTER PAGE
local function getPassage(chapterURL)
	local url = expandURL(chapterURL)
	local doc = GETDocument(url)

	local content = doc:selectFirst(".chapter-content, .content, #content")

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