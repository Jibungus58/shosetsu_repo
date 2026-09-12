-- {"id":11151412,"ver":"1.1.2","libVer":"1.0.0","author":"me","repo":"novel-bin"}

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

	local titleElement = row:selectFirst(".folio-spine-title")
	local title = titleElement and titleElement:text() or a:text()
	local img = row:selectFirst("img")
	local imageURL = ""

	if img then
		local dataSrc = img:attr("data-src")
		local src = img:attr("src")

		imageURL = dataSrc and dataSrc ~= "" and dataSrc or src
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
	local page = data[PAGE] or 1

	local url = baseURL .. "dayvisit/?page=" .. page
	local doc = GETDocument(url)

	local container = doc:selectFirst("#results-grid")
	if not container then return {} end

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
	local doc = GETDocument(baseURL .. "search?keyword=" .. data[QUERY])

	local container = doc:selectFirst("#results-grid")
	if not container then return {} end

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

-- -- NOVEL PAGE
-- local function parseNovel(novelURL)
-- 	local url = expandURL(novelURL)
-- 	local document = GETDocument(url)

-- 	local info = NovelInfo()

-- 	info:setTitle((document:selectFirst("h1") and document:selectFirst("h1"):text()) or "Unknown")

-- 	-- local author = document:selectFirst(".folio-spine-author")
-- 	-- print(info.setAuthour)
-- 	-- if author then
-- 	-- 	info:setAuthor(author:text())
-- 	-- end

-- 	local desc = document:selectFirst(".folio-synopsis-body")
-- 	if desc then
-- 		info:setDescription(desc:text())
-- 	end

-- 	local book = document:selectFirst("div.folio-detail-cover")

-- 	local imageURL = ""

-- if book then
-- 	local img = book:selectFirst("img")

-- 	if img then
-- 		imageURL = img:attr("data-src")

-- 		if imageURL == "" then
-- 			imageURL = img:attr("src")
-- 		end

-- 		if imageURL:sub(1, 1) == "/" then
-- 			imageURL = baseURL:gsub("/$", "") .. imageURL
-- 		end
-- 	end
-- end

-- info:setImageURL(imageURL)

-- 	local chapters = {}

-- 	local columns = document:select(".col-xs-12.col-sm-4.col-md-4")

-- 	for i = 0, columns:size() - 1 do
-- 		local col = columns:get(i)
-- 		local list = col:selectFirst("ol.folio-chapter-list")
-- 		print(list)
-- 		if list then
-- 			local items = list:select("li")

-- 			for j = 0, items:size() - 1 do
-- 				local li = items:get(j)
-- 				local a = li:selectFirst("a")

-- 				if a then
-- 					table.insert(chapters, NovelChapter({
-- 						title = a:text(),
-- 						link = shrinkURL(a:attr("href"))
-- 					}))
-- 				end
-- 			end
-- 		end
-- 	end

-- 	info:setChapters(chapters)

-- 	return info
-- end
-- NOVEL PAGE
local function parseNovel(novelURL)
	local url = expandURL(novelURL)
	local document = GETDocument(url)

	local info = NovelInfo()

	info:setTitle((document:selectFirst("h1") and document:selectFirst("h1"):text()) or "Unknown")

	-- Author
	-- local author = document:selectFirst(".folio-spine-author")
	-- if author then
	-- 	info:setAuthor(author:text())
	-- end

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
	-- The novel page only displays the first 24 chapters.
	-- The complete chapter list is available in the TOC on chapter 1.
	local chapters = {}

	-- Get the path of the novel without the domain.
	local novelPath = shrinkURL(url):gsub("/$", "")

	-- Open chapter 1, where Novel-Bin now exposes the full chapter list.
	local chapterOneURL = expandURL(novelPath .. "/chapter-1")

	print("Loading chapter list from: " .. chapterOneURL)

	local chapterDocument = GETDocument(chapterOneURL)

	if chapterDocument then
		-- Novel-Bin's complete chapter list.
		--
		-- Do NOT use [data-nl2-toc-body] here.
		-- Shosetsu's selector implementation may not support
		-- attribute selectors, while this class selector works.
		local chapterList = chapterDocument:selectFirst(".chapter-list-scroll")

		if chapterList then
			local links = chapterList:select("a")

			print("Found " .. links:size() .. " chapter links")

			for i = 0, links:size() - 1 do
				local a = links:get(i)

				local href = a:attr("href")
				local title = a:text()

				if href and href ~= "" then
					table.insert(chapters, NovelChapter({
						title = title,
						link = shrinkURL(expandURL(href))
					}))
				end
			end
		else
			print("ERROR: Could not find .chapter-list-scroll on chapter 1")
		end
	else
		print("ERROR: Could not load chapter 1: " .. chapterOneURL)
	end

	info:setChapters(chapters)

	return info
end


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