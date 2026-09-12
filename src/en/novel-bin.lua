
--{"id":11151412,"ver":"1.1.3","libVer":"1.0.0","author":"me","repo":"novel-bin"}

local baseURL = "https://novel-bin.net/"

-- Novel-Bin's chapter list is returned as JSON.
local json = Require("dkjson")
local function shrinkURL(url)
	return url:gsub("^https://novel%-bin%.net/", "")
end

local function expandURL(url)
	if url:match("^https?://") then
		return url
	end

	return baseURL .. url
end

local function getNovelSlug(novelURL)
	print("DEBUG novelURL = " .. tostring(novelURL))

	local url = expandURL(novelURL)
	print("DEBUG expanded URL = " .. tostring(url))

	-- Extract the slug from /novel-bin/<slug>
	local slug = url:match("/novel%-bin/([^/?#]+)")

	print("DEBUG extracted slug = " .. tostring(slug))

	return slug
end


-- HOT LIST
local function extractNovel(row)
	local a = row:selectFirst("h4 a, h3 a, .title a, .novel-title a, a[href*='/novel-bin/']")

	if not a then
		return nil
	end

	local href = a:attr("href")

	local titleElement = row:selectFirst(".folio-spine-title")
	local title = titleElement and titleElement:text() or a:text()

	local img = row:selectFirst("img")
	local imageURL = ""

	if img then
		local dataSrc = img:attr("data-src")
		local src = img:attr("src")

		imageURL = dataSrc and dataSrc ~= "" and dataSrc or src
	end

	if imageURL and imageURL:sub(1, 1) == "/" then
		imageURL = baseURL:gsub("/$", "") .. imageURL
	end

	return Novel({
		title = title,
		link = shrinkURL(href),
		imageURL = imageURL
	})
end


local function hot(data)
	local page = data[PAGE] or 1

	local url = baseURL .. "dayvisit/?page=" .. page
	local doc = GETDocument(url)

	local container = doc:selectFirst("#results-grid")

	if not container then
		return {}
	end

	local rows = container:select(".folio-spine-row")
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
	local doc = GETDocument(
		baseURL .. "search?keyword=" .. data[QUERY]
	)

	local container = doc:selectFirst("#results-grid")

	if not container then
		return {}
	end

	local rows = container:select(".folio-spine-row")
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
	local document = GETDocument(url)

	local info = NovelInfo()

	-- Title
	local title = document:selectFirst("h1")

	if title then
		info:setTitle(title:text())
	else
		info:setTitle("Unknown")
	end


	-- Description
	local desc = document:selectFirst(".folio-synopsis-body")

	if desc then
		info:setDescription(desc:text())
	end


	-- Cover image
	local book = document:selectFirst("div.folio-detail-cover")
	local imageURL = ""

	if book then
		local img = book:selectFirst("img")

		if img then
			imageURL = img:attr("data-src")

			if not imageURL or imageURL == "" then
				imageURL = img:attr("src")
			end

			if imageURL and imageURL:sub(1, 1) == "/" then
				imageURL = baseURL:gsub("/$", "") .. imageURL
			end
		end
	end

	info:setImageURL(imageURL)


	-- CHAPTERS
	--
	-- Novel-Bin's novel page only exposes the first 24 chapters.
	--
	-- The complete chapter list is available through:
	--
	-- /ajax/chapter-list?slug=<novel-slug>
	--
	-- This endpoint returns all chapters as JSON, so there is
	-- no need to open chapter 1, scroll, or scrape the lazy-loaded TOC.

	local chapters = {}

	local slug = getNovelSlug(novelURL)

	if slug then
		local chapterListURL =
			baseURL .. "ajax/chapter-list?slug=" .. slug

		print("Loading chapter list from: " .. chapterListURL)

		local data = json.GET(chapterListURL)

		if data and data.success and data.chapters then

			print("Found " .. #data.chapters .. " chapters")

			for i = 1, #data.chapters do
				local chapter = data.chapters[i]

				if chapter.url and chapter.title then

					table.insert(chapters, NovelChapter({
						title = chapter.title,
						link = shrinkURL(
							expandURL(chapter.url)
						)
					}))

				end
			end

		else
			print("ERROR: Invalid chapter list response")
		end
	else
		print("ERROR: Could not determine novel slug from URL")
	end

	info:setChapters(chapters)

	return info
end


-- CHAPTER CONTENT
local function getPassage(chapterURL)
	local doc = GETDocument(expandURL(chapterURL))

	local content = doc:selectFirst("#chr-content")

	if content then
		return content:html()
	end

	return ""
end


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

	chapterType = ChapterType.HTML,

	parseNovel = parseNovel,
	getPassage = getPassage,

	shrinkURL = shrinkURL,
	expandURL = expandURL,
}
