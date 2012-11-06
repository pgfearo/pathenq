function Element(newName, newIndex) {
    this.name = newName;
    this.index = newIndex;
    //this.childCount = 0;
    var children = {};
    var elements = new Array();
    this.addChild = function (childElement) {
        //childCount++;
        var child = childElement.name;
        if (children[child]){
            children[child] = children[child] + 1;
        } else {
            children[child] = 1;
        }
        elements.push(childElement);
    }
    this.getNameCount = function(name){
        if (children[name]){
            return children[name];
        } else {
            return 0;
        }
    }
    this.getChild = function(index){
        return elements[index];
    }
    /*
    this.getChildCount = function () {
        return childCount;
    }
    */
}

function SourceHighlighter() {

    this.highlightFromSequence = function (items) {
        if (!fileStack) {
            return;
        }
        var seqLength = items.length - 2; // 1st item is root, so miss this
        var element = fileStack.getRootElement();
        /*
        var sLog = "";
        for (var i = 0; i < items.length; i++) {
            sLog = sLog + "/" + items[i];
        }
        */
        var eLog = "";
        for (var i = seqLength; i > -1; i--) {
            var x = items[i] - 1;
            eLog = eLog + "/" + x;
            element = element.getChild(x);
            if (!element) {
                eLog = "not found";
            }
        }
        var elementPosition = element.index;

        var openTag = window.document.getElementById("id" + elementPosition);
        var closeTag = window.document.getElementById("idx" + elementPosition);
        var closeTagClass = closeTag.getAttribute("class");
        if (closeTagClass == "ec") {
            closeTag = closeTag.previousSibling;
        }

        var topTag = fileStack.swapTopTag(openTag);
        var bottomTag = fileStack.swapBottomTag(closeTag);

        doHighlight(topTag, false);
        doHighlight(bottomTag, false);

        doHighlight(openTag, true);
        doHighlight(closeTag, true);
        if (!dTextScroll) {
            openTag.scrollIntoView(true);
        }
    }
}

var dTextScroll = false;
var disableTextScroll = function () {
    //isResultsTabFocused = false; // because tree-view now has focus
    dTextScroll = true;
}
var enableTextScroll = function () {
    dTextScroll = false;
}
var isTextScrollDisabled = function () {
    return dTextScroll;
}

var sourceHighlighter = new SourceHighlighter();
var highlightSourceFromTree = function (sequence) {
    if (isHideStateOff()) {
        sourceHighlighter.highlightFromSequence(sequence);
    }
}

function doHighlight(tag, forShow) {
    if (tag) {
        var color = (forShow) ? "yellow" : "white";
        tag.style.backgroundColor = color;
    }
}

function Stack() {
    var items = new Array(); // stack of element objects
    var paths = new Array(); // array of string paths
    // add new element and return its position
    var rootElement;
    var currentTopTag = null;
    var currentBottomTag = null;

    this.swapTopTag = function (tag) {
        var temp = currentTopTag;
        currentTopTag = tag;
        return temp;
    }
    this.hideCurrentTags = function(){
        doHighlight(currentTopTag, false);
        doHighlight(currentBottomTag, false);
        currentTopTag = null;
        currentBottomTag = null;
    }
    this.swapBottomTag = function (tag) {
        var temp = currentBottomTag;
        currentBottomTag = tag;
        return temp;
    }
    this.getRootElement = function () {
        return rootElement;
    }
    this.push = function(val){
        var element = new Element(val, paths.length);
        // if parent exists add to children
        if (items.length > 0) {
            items[items.length - 1].addChild(element);
        } else {
            rootElement = element;
        }
        items.push(element);
        paths.push(""); // a path for every new element
        return "id" + (paths.length - 1);
    }
    // close element, record path for element and position
    this.pop = function(){
        var pIndex = this.storePath(this.getPath());
        items.pop();
        return "idx" + pIndex;
    }
    this.getPath = function(){
        var path = "";
        for (var a = 0; a < items.length; a++){
            var name = items[a].name;
            path += ('/' + name);
            var pred = "";
            if (a > 0){
                pred = '[' + items[a - 1].getNameCount(name) + ']';
            }
            path += pred;
        }
        return path;
    }
    this.getPathFromIndex = function (pathIndex) {
        return paths[pathIndex];
    }
    this.storePath = function (path) {
        var pathIndex = items[items.length - 1].index;
        paths[pathIndex] = path;
        return pathIndex;
    }
    this.getPaths = function(){
        return paths;
    }
    this.getPathIndex = function () {
        if (items && items.length > 0) {
            return items[items.length - 1].index;
        } else {
            return 0;
        }
    }
}
var test = function(){
    var s = new Stack();
    s.push("booklist");
    s.push("books");
    for (var a = 0; a < 4; a++){
        s.push("book");
            s.push("title"); s.pop();
            s.push("price"); s.pop();
            s.push("quantity"); s.pop();
            s.push("quantity"); s.pop();
        s.pop(); //book
    }
    
    s.pop(); //books
    s.pop(); //booklist
    var paths = s.getPaths();
    for (var i = 0; i < paths.length; i++){
        console.log(paths[i]);
    }
}

var showStack = function () {
    var s = fileStack;
    var paths = s.getPaths();
    for (var i = 0; i < paths.length; i++) {
        console.log(paths[i]);
    }
}