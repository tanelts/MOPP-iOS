//
//  NSString+Additions.swift
//  MoppApp
//
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

extension String {
    func filenameComponents() -> (name:String,ext:String) {
        if let range = self.range(of: ".", options: .backwards, range: nil, locale: nil) {
            let nameRange = self.startIndex ..< range.upperBound
            let extRange = range.lowerBound ..< self.endIndex
            var name = self
            var ext = self
            name.removeSubrange(extRange)
            ext.removeSubrange(nameRange)
            return (name:name, ext:ext)
        } else {
            return (name:self, ext:String())
        }
    }

    func substr(offset: Int, count: Int) -> String? {
        guard offset < self.count
            else { return nil }
        guard count > 0
            else { return String() }
        guard (count + offset) <= self.count
            else { return nil }
        let start   = index(startIndex, offsetBy: offset)
        let end     = index(start, offsetBy: count)
        return String(describing: self[start..<end])
    }
    
    subscript(offset: Int) -> Character? {
        guard offset < self.count
            else { return nil }
        return self[index(startIndex, offsetBy: offset)]
    }

    func lastOf(ch: Character) -> Int? {
        guard let start = self.reversed().index(of: ch) else {
            return nil
        }
        return distance(from: startIndex, to: start.base) - 1
    }
    
    var isContainerExtension: Bool {
        let ext = self.lowercased()
        return
            ext == ContainerFormatDdoc    ||
            ext == ContainerFormatAsice   ||
            ext == ContainerFormatBdoc
    }
    
}