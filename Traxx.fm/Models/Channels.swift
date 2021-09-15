//
//  Channels.swift
//  Traxx.fm
//
//  Created by Christopher Alford on 23/5/21.
//

import Foundation

struct Channel: Decodable {
    var id: String
    var endpoint: String
}


class TraxxChannels: ObservableObject {
    
    @Published var channels: [Channel] = [
        Channel(id:"Deluxe", endpoint:"http://traxx001.ice.infomaniak.ch/traxx001-low.mp3"),
        Channel(id:"House", endpoint:"http://traxx002.ice.infomaniak.ch/traxx002-low.mp3"),
        Channel(id:"Electro", endpoint:"http://traxx003.ice.infomaniak.ch/traxx003-low.mp3"),
        Channel(id:"Lounge", endpoint:"http://traxx004.ice.infomaniak.ch/traxx004-low.mp3"),
        Channel(id:"Cool Jam", endpoint:"http://traxx005.ice.infomaniak.ch/traxx005-low.mp3"),
        Channel(id:"Soul", endpoint:"http://traxx006.ice.infomaniak.ch/traxx006-low.mp3"),
        Channel(id:"R'n'B", endpoint:"http://traxx007.ice.infomaniak.ch/traxx007-low.mp3"),
        Channel(id:"Latino", endpoint:"http://traxx008.ice.infomaniak.ch/traxx008-low.mp3"),
        Channel(id:"Pop", endpoint:"http://traxx009.ice.infomaniak.ch/traxx009-low.mp3"),
        Channel(id:"Hits", endpoint:"http://traxx010.ice.infomaniak.ch/traxx010-low.mp3"),
        Channel(id:"Ambient", endpoint:"http://traxx011.ice.infomaniak.ch/traxx011-low.mp3"),
        Channel(id:"Classic", endpoint:"http://traxx012.ice.infomaniak.ch/traxx012-low.mp3"),
        Channel(id:"Deep", endpoint:"http://traxx013.ice.infomaniak.ch/traxx013-low.mp3"),
        Channel(id:"Jazz", endpoint:"http://traxx014.ice.infomaniak.ch/traxx014-low.mp3"),
        Channel(id:"Rap", endpoint:"http://traxx015.ice.infomaniak.ch/traxx015-low.mp3"),
        Channel(id:"Funk", endpoint:"http://traxx016.ice.infomaniak.ch/traxx016-low.mp3"),
        Channel(id:"Gold Hits", endpoint:"http://traxx017.ice.infomaniak.ch/traxx017-low.mp3"),
        Channel(id:"Dance", endpoint:"http://traxx018.ice.infomaniak.ch/traxx018-low.mp3"),
        Channel(id:"Rock", endpoint:"http://traxx019.ice.infomaniak.ch/traxx019-low.mp3"),
        Channel(id:"Tech", endpoint:"http://traxx020.ice.infomaniak.ch/traxx020-low.mp3")
    ]
    
//    init() {
//        if let path = Bundle.main.url(forResource: "traxx_channels", withExtension: "json") {
//            do {
//                let json = try Data(contentsOf: path)
//                let c = try JSONDecoder().decode([Channel].self, from: json)
//                self.channels = c
//            } catch let error {
//                print(error)
//            }
//        }
//    }
}
