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


extension NSBezierPath {
    
    func newCGPath() -> CGPath! {
        
        if (self.elementCount == 0) {
            return nil
        }
        let path: CGMutablePath = CGPathCreateMutable()
        var points = [NSPoint](count: 3, repeatedValue: NSZeroPoint)
        var didClosePath = false
        for i in 0..<self.elementCount {
            switch (self.elementAtIndex(i, associatedPoints: &points)) {
            case .MoveToBezierPathElement:
                CGPathMoveToPoint(path, nil, points[0].x, points[0].y)
            case .LineToBezierPathElement:
                CGPathAddLineToPoint(path, nil, points[0].x, points[0].y);
                didClosePath = false
            case .CurveToBezierPathElement:
                CGPathAddCurveToPoint(path, nil, points[0].x, points[0].y, points[1].x, points[1].y, points[2].x, points[2].y);
                didClosePath = false;
            case .ClosePathBezierPathElement:
                CGPathCloseSubpath(path)
                didClosePath = true
            }
        }
        if !didClosePath {
            CGPathCloseSubpath(path)
        }
        return CGPathCreateCopy(path)
    }

}
