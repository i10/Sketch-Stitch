# Sketch&Stitch

------------

Contributers: Nur Hamdan and **Kirill Krasnoshchokov**

RWTH Aachen University, Germany

Funding:  EU and the state of NRW in Germany. Project 3D Competence Center // 3D-Kompetenzzentrum Niederrhein

Contact hamdan@cs.rwth-aachen.de

------------

The main purpose of this application is to create smart textiles from a sketch on fabric. The application allows users to snap/upload a colored sketch. It then separates the sketch into a number of files, each containing the lines of a single color. It can smooth the lines using an outline or centerline options. The application allows the user to determine which colors should be stitched with conductive yarn, and which should be stitched with regular yarn. An accompanying software communicates with embroidery machine software to convert each colored file into an embroidery pattern. Users may use Circuitry Stickers, custom stickers that can be added to a sketch to represent physical electrical components and custom stitch patterns, such as wire crossings and 2D matrix sensors.

This application was part of a research project published at ACM CHI 2018.

ACM Reference Format: Nur Al-huda Hamdan, Simon Voelker, Jan Borchers. 2018. Sketch&Stitch: Interactive Embroidery for E-Textiles. In CHI Conference on Human Factors in Computing Systems Proceedings (CHI 2018), April 21–26, 2018, Montreal QC, Canada. ACM, New York, NY, USA, 13 pages. https://doi.org/10.1145/3173574.3173656

For access to the paper and videos see: https://hci.rwth-aachen.de/sketchstitch

------------

**How To Run The Application**

From the 'master' branch, download '190711 S&S Suite'.

Mac OS App
  From the Terminal 
    sudo gem install cocoapods
    cd /<path to SketchAndStitch3>
    pod install
  From Xcode
    Compile ⁨190711 S&S Suite⁩ ▸ ⁨Source Code macOS⁩ ▸ ⁨SketchAndStitch3⁩ ▸ SketchAndStitch3.xcworkspace


iOS App
  From the Terminal 
    sudo gem install cocoapods
    cd /<path to SketchAndStitchCompanion>
    pod install
  From Xcode
    Compile ⁨190711 S&S Suite⁩ ▸ ⁨Source Code iOS⁩ ▸ ⁨SketchAndStitchCompanion⁩ ▸ SketchAndStitchCompanion.xcworkspace


Embroidery automator Appl (Win)
  Read 190711 S&S Suite⁩ ▸ ⁨Bernina Software Automation⁩ ▸ HOWTO.txt and BerninaSoftwareSetup.PNG
  Run 190711 S&S Suite⁩ ▸ ⁨Bernina Software Automation⁩ ▸ Bernina Automation.exe
  
