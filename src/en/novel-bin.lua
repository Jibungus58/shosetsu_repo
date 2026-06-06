-- {"id":11151412,"ver":"1.0.0","libVer":"1.0.0","author":"me","repo":"novel-bin"}

local baseURL = "https://novel-bin.net/"

local function shrinkURL(url)
	return url:gsub(baseURL, "")
end

local function expandURL(url)
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

			if a then
				table.insert(novels, Novel({
					title = a:text(),
					link = shrinkURL(a:attr("href")),
					imageURL = img and img:attr("src") or ""
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

			if a then
				table.insert(novels, Novel({
					title = a:text(),
					link = shrinkURL(a:attr("href")),
					imageURL = img and img:attr("src") or ""
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