-- {"id":11151410,"ver":"1.0.2","libVer":"1.0.0","author":"me","repo":"noveldex"}

local baseURL = "https://noveldex.io/"

local function shrinkURL(url)
    return url
        :gsub("^https://noveldex%.io", "")
        :gsub("%?.*$", "")
end

local function expandURL(url)
    if url:match("^https?://") then
        return url
    end

    return baseURL:gsub("/$", "") .. url
end
-- HOT LIST
local function extractNovel(row)
    local a = row:selectFirst("a[href*='/series/']")

    if not a then return nil end

local img = a:selectFirst("img")

local imageURL = ""

if img then
    imageURL = img:attr("src")

    if imageURL:sub(1,1) == "/" then
        imageURL = "https://noveldex.io" .. imageURL
    end
end
local function hot(data)
    local page = data[PAGE] or 1

    local doc = GETDocument(
        baseURL .. "series?sort=popular&page=" .. page
    )

    local novels = {}

    local rows = doc:select("div.group[role=gridcell]")

    for i = 0, rows:size() - 1 do
        local novel = extractNovel(rows:get(i))

        if novel then
            table.insert(novels, novel)
        end
    end

    return novels
end
local function search(data)
    local query = data[QUERY]

    local doc = GETDocument(
        baseURL .. "search?q=" .. query
    )

    local novels = {}

    local rows = doc:select("div.group[role=gridcell]")

    for i = 0, rows:size() - 1 do
        local novel = extractNovel(rows:get(i))

        if novel then
            table.insert(novels, novel)
        end
    end

    return novels
end
-- NOVEL PAGE
local function parseNovel(novelURL)
	local url = expandURL(novelURL)
	local document = GETDocument(url)

	local info = NovelInfo()

	info:setTitle((document:selectFirst("h1") and document:selectFirst("h1"):text()) or "Unknown")

	local author = document:selectFirst(".author")
	if author then
		info:setAuthor(author:text())
	end

	local desc = document:selectFirst("div.desc-text")
	if desc then
		info:setDescription(desc:text())
	end

	local book = document:selectFirst("div.book")

	local imageURL = ""

if book then
	local img = book:selectFirst("img.object-cover")

	if img then
		imageURL = img:attr("data-src")

		if imageURL == "" then
			imageURL = img:attr("src")
		end

		if imageURL:sub(1, 1) == "/" then
			imageURL = baseURL:gsub("/$", "") .. imageURL
		end
	end
end

info:setImageURL(imageURL)

	info:setImageURL(imageURL)

	-- chapters (your existing working logic)
local chapters = {}

local chapterContainer =
    document:selectFirst("div.divide-y")

if chapterContainer then

	local links = document:select("a[href*='/chapter/']")

print("chapter count = " .. links:size())
end

info:setChapters(chapters)


-- CHAPTER PAGE
local function getPassage(chapterURL)
    local doc = GETDocument(expandURL(chapterURL))

    local content =
        doc:selectFirst("section[data-chapter-id]")

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
	id = 11151410,
	name = "noveldex",
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