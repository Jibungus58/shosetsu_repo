local json = Require("dkjson")

local BASE_URL = "https://novel-bin.net/"

return {
    id = 8235698765432,
    name = "Novel-bin",
    version = 1.0.0,

    listings = {
        {
            name = "Latest Updates",
            isIncrementing = false,
            method = function(data)
                return {}
            end
        }
    },

    search = function(data)
        local query = data[QUERY]

        local url = BASE_URL .. "/search?keyword=" .. query
        local html = GET(url)

        local novels = {}

        -- Parse results here
        -- table.insert(novels, Novel {
        --     title = "Novel Title",
        --     link = "/novel/example/",
        --     imageURL = "https://..."
        -- })

        return novels
    end,

    parseNovel = function(novelURL, loadChapters)
        local html = GET(BASE_URL .. novelURL)

        return NovelInfo {
            title = "Novel Title",
            imageURL = "",
            description = "",
            genres = {},
            authors = {},
            status = NovelStatus.UNKNOWN,

            chapters = loadChapters and {
                Chapter {
                    title = "Chapter 1",
                    link = "/chapter-1"
                }
            } or nil
        }
    end,

    getPassage = function(chapterURL)
        local html = GET(BASE_URL .. chapterURL)

        local document = Document(html)

        -- Remove unwanted elements
        -- document:select(".ads"):remove()

        local content = document:selectFirst(".chapter-content")

        return pageOfElem(content)
    end
}