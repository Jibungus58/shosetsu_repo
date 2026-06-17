-- {"id":11151410,"ver":"1.0.2","libVer":"1.0.0","author":"me","repo":"noveldex"}

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

    local rows = doc:select("div.group")

    local novels = {}

    for i = 0, rows:size() - 1 do
        local row = rows:get(i)

        local a = row:selectFirst("a[href*='/series/']")

        local img = row:selectFirst("img")

        if a then
            local title = img and img:attr("alt") or a:text()

            local imageURL = ""
            if img then
                imageURL = img:attr("src") or ""
                if imageURL:sub(1,1) == "/" then
                    imageURL = baseURL .. imageURL
                end
            end

            table.insert(novels, Novel({
                title = title,
                link = shrinkURL(a:attr("href")),
                imageURL = imageURL
            }))
        end
    end

    return novels
end

----------------------------------------------------
-- SEARCH
----------------------------------------------------

local function search(data)
    local query = data[QUERY]

    local json = Request(
        baseURL .. "/api/search?q=" .. query
    )

    local obj = JSON.decode(json)

    local novels = {}

    for _, s in ipairs(obj.series or {}) do
        table.insert(novels, Novel({
            title = s.title,
            link = "/series/" .. s.slug,
            imageURL = s.coverImage and (baseURL .. s.coverImage) or ""
        }))
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
    local img =
        cover:attr("src")
        or cover:attr("data-src")

    if img and img:sub(1,1) == "/" then
        img = baseURL .. img
    end

    info:setImageURL(img)
end

    ------------------------------------------------
    -- CHAPTERS
    ------------------------------------------------

    local chapters = {}

    local links = document:select("a[href*='/chapter/']")

    for i = 0, links:size() - 1 do
        local a = links:get(i)

        local href = a:attr("href")

        -- HARD FILTER: real chapters always include /chapter/{number}
        if href and href:match("/chapter/%d+") then

            local titleNode = a:selectFirst("span.font-medium")

            local title =
                titleNode and titleNode:text()
                or a:text()

            -- FILTER OUT UI BUTTONS
            if title and title ~= "" and not title:lower():find("start reading") then
                table.insert(chapters, NovelChapter({
                    title = title,
                    link = shrinkURL(href)
                }))
            end
        end
    end

    info:setChapters(chapters)

    return info
end

----------------------------------------------------
-- CHAPTER CONTENT
----------------------------------------------------

local function getPassage(chapterURL)
    local doc = GETDocument(expandURL(chapterURL))

    local content = doc:selectFirst("section[data-chapter-id]")

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