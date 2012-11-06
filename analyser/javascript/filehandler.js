var fileData = {}; // collection of XMLDOM items
var fileTextData = {}; // collection of XML string items
var fileStackData = {};
var renderedFile = {}; // collection of cached copies of rendered file
var fileInstance = ""; // XMLDOM instance
var fileText = "";
var fileStack;

function handleFileSelect(evt) {
    evt.stopPropagation();
    evt.preventDefault();
    var files = evt.target.files; // FileList object - used with button
    if (files == null) {
        if (evt.dataTransfer) {
            files = evt.dataTransfer.files; // used with drag and drop
        }
    }
    evt.target.style.background = "#8c9ace";

    // Loop through the FileList
    for (var i = 0, f; f = files[i]; i++) {

        // Only process non-image files.
        // fileType may be text/xml or text/html etc..
        var fileType = f.type;
        if (fileType.match('image.*')) {
            continue;
        }
        var isHTML = false; //until this works properly -don't use fileType.match('html');

        var reader = new FileReader();

        // Closure to capture the file information.
        reader.onload = (function (theFile, filesLength) {
            return function (e) {
                // Render para               
                var localText = e.target.result;

                writeToAppConsole('<p>Loaded file:<br>' + theFile.name + '</p>');

                if (filesLength == 1) {
                    // if there's only one file -make this the active file
                    fileText = localText;
                    if (isHTML) {
                        window.alert("ishtml");
                        fileInstance = window.document.implementation.createHTMLDocument("");
                        fileInstance.documentElement.innerHTML = fileText;
                    }
                    else {
                        fileInstance = Saxon.parseXML(fileText);
                    }
                    if (fileInstance == null) {
                        // error will have been reported by errorHandler
                        writeToAppConsole('<p><span class="console-error">[Error]</span><br> XML parser error loading file:<br>' + theFile.name + '</p>');
                    } else {
                        addNewHotFileSpan(theFile.name);
                    }
                } else {
                    // otherwise just create the button and init arrays
                    initEmptyButtonData(theFile.name, localText);
                    // create dom and stack later
                    createSpanButton(theFile.name, false);
                }


            };
        })(f, files.length);

        // Read in the text file
        reader.readAsText(f);
    }
    return false;
}

document.getElementById('xfiles').addEventListener('change', handleFileSelect, false);

function initEmptyButtonData(filename, fileText) {
    fileTextData[filename] = fileText;
    fileStackData[filename] = null;
    fileData[filename] = null;
}

function handleDragOver(evt) {
    evt.stopPropagation();
    evt.preventDefault();
    evt.dataTransfer.dropEffect = 'copy'; // Explicitly show this is a copy.
    //this.style.background = "#8c9ace";
    return false;
}

function doc(filename) {
    if (fileData[filename]) {
        return fileData[filename];
    } else {
        return null;
    }
}

function handleDragEnter(e) {
    // this / e.target is the current hover target
    e.stopPropagation();
    e.preventDefault();
    this.style.background = "#506090";
    this.style.cursor = "move";
    return false;
}

function handleDragLeave(e) {
    this.style.background = "#8c9ace";
    this.style.cursor = "default";
}

var dropZone = document.getElementById('drop_zone');
dropZone.addEventListener('dragover', handleDragOver, false);
dropZone.addEventListener('drop', handleFileSelect, false);
dropZone.addEventListener('dragenter', handleDragEnter, false);
dropZone.addEventListener('dragleave', handleDragLeave, false);
