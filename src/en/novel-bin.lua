local BASE_URL = "https://novel-bin.net"

return {
    id = 11151412,
    name = "Novel-bin",
    version = 1,

    listings = {},

    search = function(data)
        return {}
    end,

    parseNovel = function(url, loadChapters)
        return NovelInfo {
            title = "Test"
        }
    end,

    getPassage = function(url)
        return {}
    end
}