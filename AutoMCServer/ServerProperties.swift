import Cocoa

enum GameMode: Int {
    case Survival = 0
    case Creative = 1
    case Adventure = 2
}

enum Difficulty: Int {
    case Peaceful = 0
    case Easy = 1
    case Normal = 2
    case Hard = 3
}

enum LevelType {
    case DEFAULT, FLAT, LARGEBIOMES, AMPLIFIED
}

class ServerProperties {
    var nether: Bool
    var leveltype: LevelType
    var mobs: Bool
    var whitelist: Bool
    var pvp: Bool
    var difficulty: Difficulty
    var gamemode: GameMode
    var maxplayers: Int
    var motd: String
    
    init(nether:Bool, leveltype:LevelType, mobs:Bool, whitelist:Bool,pvp:Bool, difficulty:Difficulty, gamemode:GameMode, maxplayers:Int, motd:String) {
        self.nether = nether
        self.leveltype = leveltype
        self.mobs = mobs
        self.whitelist = whitelist
        self.pvp = pvp
        self.difficulty = difficulty
        self.gamemode = gamemode
        self.maxplayers = maxplayers
        self.motd = motd
    }
}
