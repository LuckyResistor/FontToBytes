//
// Lucky Resistor's Font to Byte
// ---------------------------------------------------------------------------
// (c)2015 by Lucky Resistor. See LICENSE for details.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//


import Cocoa


/// The byte writer for the conversion algorithm to send the result to.
///
protocol ByteWriter {
    
    /// Start a new file
    ///
    /// Call this method once at the begin, before any data is written.
    ///
    func begin()
    
    /// Starts a new array of bytes
    ///
    /// - parameters:
    ///   - name: The name of the array.
    ///
    func beginArray(_ name: String)
    
    /// Write a single byte to the output array.
    ///
    func writeByte(_ byte: UInt8)
    
    /// Add a comment and linebrak to the output.
    ///
    func addComment(_ comment: String)
    
    /// Add just a linebreak to the output.
    ///
    func addLineBreak()
    
    /// Ends an array of bytes.
    ///
    func endArray()
    
    /// End a file
    ///
    /// Call this method once at the end, after all data was written.
    ///
    func end()
}


