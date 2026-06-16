-- {"id":11151410,"ver":"1.0.0","libVer":"1.0.0","author":"me","repo":"noveldex"}

local baseURL = "https://noveldex.io"

----------------------------------------------------
-- URL HELPERS
----------------------------------------------------

local function shrinkURL(url)
    if not url then return "" end
    return url
        :gsub("^https?://noveldex%.io", "")
        :gsub("%?.*$", "")
end

local function expandURL(url)
    if url:match("^https?://") then
        return url
    end
    return baseURL .. url
end

----------------------------------------------------
-- HOT + SEARCH COMMON EXTRACTOR
----------------------------------------------------

local function extractNovel(row)
    if not row then return nil end

    local a = row:selectFirst("a[href*='/series/']")
    if not a then return nil end

    local img = a:selectFirst("img")

    local imageURL = ""
    if img then
        imageURL =
            img:attr("src")
            or img:attr("data-src")
            or ""

        if imageURL:sub(1,1) == "/" then
            imageURL = baseURL .. imageURL
        end
    end

    local title =
        img and img:attr("alt")
        or a:text()
        or "Unknown"

    return Novel({
        title = title,
        link = shrinkURL(a:attr("href")),
        imageURL = imageURL
    })
end

----------------------------------------------------
-- HOT LIST
----------------------------------------------------

local function hot(data)
    local page = data[PAGE] or 1

    local doc = GETDocument(
        baseURL .. "/series?sort=popular&page=" .. page
    )

    local rows = doc:select("div.group[role=gridcell]")

    local novels = {}

    for i = 0, rows:size() - 1 do
        local n = extractNovel(rows:get(i))
        if n then table.insert(novels, n) end
    end

    return novels
end

----------------------------------------------------
-- SEARCH
----------------------------------------------------

local function search(data)
    local query = data[QUERY]

    local doc = GETDocument(
        baseURL .. "/search?q=" .. query
    )

    local rows = doc:select("div.group[role=gridcell]")

    local novels = {}

    for i = 0, rows:size() - 1 do
        local n = extractNovel(rows:get(i))
        if n then table.insert(novels, n) end
    end

    return novels
end

----------------------------------------------------
-- NOVEL PAGE
----------------------------------------------------

local function parseNovel(novelURL)
    local url = expandURL(novelURL)
    local document = GETDocument(url)

    local info = NovelInfo()

    -- TITLE
    local title = document:selectFirst("h1")
    if title then
        info:setTitle(title:text())
    end

    -- AUTHOR (best-effort)
    local author = document:selectFirst(".author")
    if author then
        info:setAuthor(author:text())
    end

    -- DESCRIPTION (fallback-safe)
    local desc =
        document:selectFirst(".desc-text")
        or document:selectFirst("[class*=description]")

    if desc then
        info:setDescription(desc:text())
    end

    -- COVER IMAGE
    local cover = document:selectFirst("img.object-cover")

    if cover then
        local imgURL =
            cover:attr("src")
            or cover:attr("data-src")

        if imgURL and imgURL:sub(1,1) == "/" then
            imgURL = baseURL .. imgURL
        end

        if imgURL then
            info:setImageURL(imgURL)
        end
    end

    ------------------------------------------------
    -- CHAPTERS
    ------------------------------------------------

    local chapters = {}

    local links = document:select("a[href*='/chapter/']")

    for i = 0, links:size() - 1 do
        local a = links:get(i)

        local titleNode = a:selectFirst("span.font-medium")

        local chapterTitle =
            titleNode and titleNode:text()
            or a:text()
            or "Chapter"

        table.insert(chapters, NovelChapter({
            title = chapterTitle,
            link = shrinkURL(a:attr("href"))
        }))
    end

    info:setChapters(chapters)

    return info
end

----------------------------------------------------
-- CHAPTER CONTENT
----------------------------------------------------

local function getPassage(chapterURL)
    local doc = GETDocument(expandURL(chapterURL))

    local content =
        doc:selectFirst("section[data-chapter-id]")
        or doc:selectFirst("section")

    if content then
        return content:html()
    end

    return ""
end

----------------------------------------------------
-- LISTINGS
----------------------------------------------------

local listings = {
    Listing("Hot", true, hot),
}

----------------------------------------------------
-- RETURN
----------------------------------------------------

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