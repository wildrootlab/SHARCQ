var ci = app.activeDocument.countItems
var plist = "ItemNumber\tXpos\tYpos\n"
var tp = activeDocument.path.fsName + "/" + documents[0].name.slice(0,-4) + ".txt";
for (var i = 0; i < ci.length; i++){
    var pos = ci[i].position.toString().split(",")
    plist= plist + (i+1) + "\t" + pos[0] +"\t" + pos[1] + "\n"
};
writeText(tp, plist)
function writeText(p,s) {
    var file = new File(p.toString());
    file.encoding = 'UTF-8';
    file.open('w');
    file.write(s);
    file.close();
}
