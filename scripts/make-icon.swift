import AppKit
import Foundation
guard CommandLine.arguments.count==2 else{fatalError("Usage: swift make-icon.swift output.png")}
let bitmap=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:1024,pixelsHigh:1024,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:bitmap)
let base=NSBezierPath(roundedRect:NSRect(x:40,y:40,width:944,height:944),xRadius:210,yRadius:210)
NSGradient(starting:NSColor(calibratedRed:0.12,green:0.32,blue:0.65,alpha:1),ending:NSColor(calibratedRed:0.03,green:0.11,blue:0.29,alpha:1))!.draw(in:base,angle:90)
NSColor.white.setFill();NSBezierPath(roundedRect:NSRect(x:245,y:200,width:500,height:640),xRadius:42,yRadius:42).fill()
NSColor(calibratedRed:0.16,green:0.31,blue:0.52,alpha:1).setFill()
("M" as NSString).draw(in:NSRect(x:306,y:480,width:380,height:230),withAttributes:[.font:NSFont.systemFont(ofSize:230,weight:.heavy),.foregroundColor:NSColor(calibratedRed:0.16,green:0.31,blue:0.52,alpha:1)])
for y in [380,300]{NSBezierPath(roundedRect:NSRect(x:315,y:y,width:350,height:22),xRadius:11,yRadius:11).fill()}
NSColor(calibratedRed:0.35,green:0.93,blue:0.76,alpha:1).setFill();let star=NSBezierPath();star.move(to:NSPoint(x:760,y:470));star.line(to:NSPoint(x:788,y:392));star.line(to:NSPoint(x:866,y:365));star.line(to:NSPoint(x:788,y:338));star.line(to:NSPoint(x:760,y:260));star.line(to:NSPoint(x:732,y:338));star.line(to:NSPoint(x:654,y:365));star.line(to:NSPoint(x:732,y:392));star.close();star.fill()
NSGraphicsContext.restoreGraphicsState();try bitmap.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:CommandLine.arguments[1]))
