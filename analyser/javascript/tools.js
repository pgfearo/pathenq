
onSaxonLoad = function () {

    setStartupSample();
    Saxon.setErrorHandler(eh);
    Saxon.run({
        initialTemplate: "main",
        stylesheet: "xsl/xpathcolorer.xsl",
        logLevel: "INFO"
    })
}

var item;
var dScroll = false;
var disableScroll = function () {
    isResultsTabFocused = false; // because tree-view now has focus
    isXPathEditorFocused = false;
    dScroll = true;
}
var enableScroll = function () {
    dScroll = false;
}
var swapItem = function (newItem) {
    if (!(dScroll)) {
        newItem.scrollIntoView(true);
    }
    var prevItem = item;
    item = newItem;
    return prevItem
};

var getEventTarget = function(e) {
    var targ;
    if (e.target) targ = e.target;
    else if (e.srcElement) targ = e.srcElement;
    if (targ.nodeType == 3) { // defeat Safari bug
        targ = targ.parentNode;
    }
    return targ;
}

var getHotItem = function () {
    return item;
}

var preventDefault = function (inEvent) {
    if (typeof inEvent.preventDefault == 'function') {
        inEvent.preventDefault();
    } else if (inEvent.returnValue) {
        inEvent.returnValue = false;
    }
}



var currentX = "original";

function swapId(x) {
         var oldX = currentX;
         currentX = x; 
         return oldX;
}

function getId(x) {
        return currentX;
}

function setTraceLocation(newhref) {
        window.location = newhref; 
}
var expr;

var setExpr = function(inExpr){
                expr = inExpr;
};
var getExpr = function(){
                return expr;
};

var setStartupSample = function () {
    getFile("samples/sample.xml");
}

var addFileFromURL = function (xmlURL) {
    var fullURL = "../../proxy.ashx?" + xmlURL;
    getFile(fullURL);
}

var getFile = function (xmlURL) {
    var xmlhttpURL = xmlURL;
    if (typeof XMLHttpRequest == "undefined") {
        XMLHttpRequest = function () {
            try { return new ActiveXObject("Msxml2.XMLHTTP.6.0"); }
            catch (e) { }
            try { return new ActiveXObject("Msxml2.XMLHTTP.3.0"); }
            catch (e) { }
            try { return new ActiveXObject("Microsoft.XMLHTTP"); }
            catch (e) { }
        };
    }
    var xmlhttp = new XMLHttpRequest();
    xmlhttp.onreadystatechange = handleStateChange(xmlhttp, xmlhttpURL);

    xmlhttp.open("GET", xmlhttpURL, true);
    xmlhttp.send(null);
};

var splitString = function (inText) {
    return inText.split("<");
}

var splitElementName = function (inText) {
    return inText.split(/>|\s+|\//g);
}

var pred = new Array();

var initPredCount = function (inPredName, index) {
    pred[index] = { predName: inPredName, predCount: 0 }
}
var getPredCount = function (nameTest, index) {
        var pName = pred[index].predName.toString();
        var xName = nameTest.toString();
        if (xName == pName) {
            pred[index].predCount = pred[index].predCount + 1;
        }
        return pred[index].predCount;
}

var rgxAtt = /(\S+)|(\s+)/g;
var splitAttributeName = function (inText) {
    return inText.match(rgxAtt);
}

var rgxWrd = /[\S]/;
var isWord = function (inText) {
    return rgxWrd.test(inText);
}

var hotElement; // is colorized but also stores current filename

var getHotName = function () {
    return hotElement.childNodes[0].nodeValue; // should be just the text node
}

// called after async fetch of sample.xml
var handleResponse = function (status, response, xmlhttpURL) {
    fileText = response;
    writeToAppConsole('<p>Loaded file:<br>' + xmlhttpURL + '</p>');

    fileInstance = Saxon.parseXML(response);
    if (fileInstance == null) {
        // error will have been reported by errorHandler
        writeToAppConsole('<p><span class="console-error">[Error]</span><br> XML parser error file:<br>' + theFile.name + '</p>');
    } else {
        addNewHotFileSpan(xmlhttpURL);
    }


}

var cacheExistingFileRender = function () {
    var existingFile = getHotName();
    if (!(renderedFile[existingFile]) && !(renderingInProgress)) {
        // cache rendered file to collection before changing this
        renderedFile[existingFile] = targetNode.innerHTML;
    }
}

function handleFileClick(filename, spanElement) {

    var existingFile = getHotName();
    if (existingFile == filename) {
        return;
    }
    if (fileStack) {
        fileStack.hideCurrentTags();
    }

    fileText = fileTextData[filename];

    if (fileData[filename]) {
        // do nothing because must have been loaded previously
    } else {
        fileStackData[filename] = new Stack();
        fileData[filename] = Saxon.parseXML(fileText);
        if (!isHideStateOff()) {
             renderCurrentXml();
        }
    }

    fileInstance = fileData[filename];
    fileStack = fileStackData[filename];

    // before modifying existing rendered file - cache it
    cacheExistingFileRender();

    renderCurrentXmlTree();
    if (isHideStateOff()) {
        if (renderedFile[filename]) {
            // use existing cache rendered form
            targetNode.innerHTML = renderedFile[filename];
        } else {
            // render from XML text
            renderCurrentXml();
        }
    }

    setButtonState(hotElement, false);
    hotElement = spanElement;
    setButtonState(spanElement, true);
}

var removeSpan = function (span, filename) {
    if (span.childNodes[0] == hotElement) {
        document.getElementById('source').innerHTML = "";
    }
    span.parentNode.removeChild(span);
    delete fileData[filename];
    delete fileTextData[filename];
    delete fileStackData[filename];
}

var addNewHotFileSpan = function (filePath) {
    // this assumes globals: fileInstance (DOM) and fileText (String) are set already
    var fileName = getFileFromPath(filePath);
    // if there's an existing filestack - hide highlights for this
    // for next time it is used
    if (fileStack) {
        fileStack.hideCurrentTags();
    }
    fileStack = new Stack();
    fileTextData[fileName] = fileText;
    fileStackData[fileName] = fileStack;
    fileData[fileName] = fileInstance;

    if (hotElement) {
        cacheExistingFileRender(); // uses hotElement
        setButtonState(hotElement, false);
    }
    hotElement = createSpanButton(filePath, true);
    renderCurrentXmlTree();
    renderCurrentXml();
}

var setButtonState = function (inElement, isHot) {

    var containerClass = (isHot) ? 'hotparent' : 'parent';
    var spanClass = (isHot) ? 'hot' : 'nothot';
    inElement.parentNode.setAttribute('class', containerClass);
    inElement.setAttribute('class', spanClass);
}

var createSpanButton = function(filePath, isHot) {
    var dz = document.getElementById('drop_zone');

    var containerElement = document.createElement("span");
    var containerText = document.createTextNode("\xa0X\xa0");
   
    var spanElement = document.createElement("span");
    var filename = getFileFromPath(filePath);
    var spanText = document.createTextNode(filename);

    spanElement.appendChild(spanText);
    containerElement.appendChild(spanElement);
    setButtonState(spanElement, isHot);
    containerElement.appendChild(containerText);
    dz.appendChild(containerElement);
    return spanElement;
}

var getSourcePath = function (pathIndex) {
    return fileStack.getPathFromIndex(pathIndex);
}
var getStackIndex = function () {
    return "idm" + fileStack.getPathIndex();
}

var getFileFromPath = function (filename) {
    var urlParts = filename.split('/');
    return urlParts[urlParts.length - 1];
}
var handleStateChange = function (inXmlHttp, inXmlURL) {
    var xmlhttp = inXmlHttp;
    var xmlURL = inXmlURL;
    var returnFunction = function () {
        switch (xmlhttp.readyState) {
            case 0: // UNINITIALIZED
            case 1: // LOADING
            case 2: // LOADED
            case 3: // INTERACTIVE
                break;
            case 4: // COMPLETED
                handleResponse(xmlhttp.status, xmlhttp.responseText, xmlURL);
                break;
            default: alert("error");
        }
    }
    return returnFunction;
}




var getHistoryData = function () {
    var foundVariables = new Array();
    var variablesTable = document.getElementById('xtbody');
    var context = '/';

    var rowIndex = 0;
    var cNodes = variablesTable.getElementsByTagName('tr');
    for (var i = 0; i < cNodes.length; i++) {
        var cNode = cNodes[i];
        var xpathVariable;
        var rowCells = cNode.getElementsByTagName('td');
        var spanTextNodes = rowCells[1].getElementsByTagName('span')[0].childNodes;
        var spanText = (spanTextNodes == null || spanTextNodes.length == 0) ? '' : spanTextNodes[0].nodeValue;
        if (spanText != null && spanText.length > 0) {

            var expressionText = cNode.getAttribute('data-expr');

            if (spanText == '.') {
                context = expressionText;
            } else {
                xpathVariable = {
                    vname: doTrim(spanText),
                    vselect: doTrim(expressionText)
                };

                foundVariables[rowIndex] = xpathVariable;
                rowIndex++;
            }
        }
    }
    result = { xpathvariables: foundVariables, xpathcontext: context };
    return result;
}

var doTrim = function (inText) {
    var result;
    if (!String.prototype.trim) {
        result = inText.replace(/^\s\s*/, '').replace(/\s\s*$/, '');
    } else {
        result = inText.trim();
    }
    return result;
}

var xslProcTree;

var renderCurrentXmlTree = function () {
    if (!xslProcTree) {
        xslProcTree = Saxon.newXSLT20Processor(Saxon.requestXML("xsl/showtree.xsl"));
    }
    xslProcTree.updateHTMLDocument(getCurrentXmlDom());
};

var getCurrentXmlDom = function () {
    return fileInstance;
}
var getCurrentXmlStack = function () {
    return fileStack;
}

var getSourceText = function () {
    return fileText;
}

var xslProcRender;

var requiredFragmentIndex;
var targetNode = document.getElementById('source');
var fragmentCollection;
var filePrefix = "file:///source";

/*
    This inititates an XSLT transform on the text of the
    currently selected XML - to pretty-print it.
    The transform first makes a call to getSourceText ,
    it then parses this and chunks the output into result
    documents that are created asynchronously. On each chunk,
    a callback is made to onCurrentXmlRendered - which in turn
    appends the result-document to the DOM
*/
var renderCurrentXml = function () {
    if (isHideStateOff()) {
        alwaysRenderXml();
    }

};

var alwaysRenderXml = function(){
    if (!xslProcRender) {
        xslProcRender = Saxon.newXSLT20Processor(Saxon.requestXML("xsl/prettyprint.xsl"));
        xslProcRender.setInitialTemplate("main");
    }
    initialiseFragments();
    xslProcRender.transformToHTMLFragment(null);
}

var initialiseFragments = function () {
    renderingInProgress = true;
    targetNode.innerHTML = "";
    requiredFragmentIndex = 0;
    fragmentCollection = new Array();
}

var stackPush = function (name) {
    return fileStack.push(name);
}
var stackPop = function () {
    return fileStack.pop();
}

var isHideStateOff = function () {
    var result = document.getElementById('hidestate').innerHTML == 'Off';
    return result;
}

var renderingInProgress = false;

var onCurrentXmlRendered = function (fragmentIndex) {
    var r = requiredFragmentIndex;
    if (fragmentIndex < 0) {
        // only happens at end
        renderingInProgress = false;

    } else if (fragmentIndex == r) {
        // should always happen
        //console.log("using current item: " + r);
        appendResultFragment(r);

    } else if (fragmentCollection[r]) {
        var delOk = delete fragmentCollection[r];
        console.log("using prev and deleting item: " + r);
        appendResultFragment(r);

    } else {
        console.log("caching item:" + fragmentCollection.length);
        fragmentCollection[fragmentIndex] = true; // store info that this is available
    }    
}

var appendResultFragment = function (fragmentIndex) {
    var resultURI = filePrefix + fragmentIndex;
    var resultFragment = xslProcRender.getResultDocument(resultURI);
    if (resultFragment) {
        targetNode.appendChild(resultFragment);
        //console.log("appended: " + fragmentIndex);
        requiredFragmentIndex++;
    }
}

var eval = function(expr) {
   var xslExpression = repNbsp(expr);

   var errDoc;

   errDoc = null;

    var xmldoc = getCurrentXmlDom();

    var historyData = getHistoryData();
    var newContext = historyData.xpathcontext;
    var xslVariables = historyData.xpathvariables;

    var res = getXmlns(xmldoc);
    var xmlnsStr = res.str;
    var xmlnsDef = res.def

    var templateBody = makeTemplateCall(xmlnsDef, xmlnsStr, newContext, xslVariables, xslExpression);

    var xslTextNew = '<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:js="http://saxonica.com/ns/globalJS" xmlns:f="urn:local-function" version="2.0"  >  <xsl:template match="/"> <top>' + templateBody + '</top> </xsl:template>  <xsl:template name="wrap"> <xsl:param name="c" as="item()*"/> <xsl:for-each select="$c"> <result type="{if (. instance of xs:boolean) then \'xs:boolean\' else if (. instance of xs:integer) then \'xs:integer\' else if (. instance of xs:decimal) then \'xs:decimal\' else if (. instance of xs:float) then \'xs:float\' else if (. instance of xs:double) then \'xs:double\' else if (. instance of xs:string) then \'xs:string\' else if (. instance of xs:QName) then \'xs:QName\' else if (. instance of xs:anyURI) then \'xs:anyURI\' else if (. instance of xs:hexBinary) then \'xs:hexBinary\' else if (. instance of xs:base64Binary) then \'xs:base64Binary\' else if (. instance of xs:date) then \'xs:date\' else if (. instance of xs:dateTime) then \'xs:dateTime\' else if (. instance of xs:time) then \'xs:time\' else if (. instance of xs:duration) then \'xs:duration\' else if (. instance of xs:gYear) then \'xs:gYear\' else if (. instance of xs:gYearMonth) then \'xs:gYearMonth\' else if (. instance of xs:gMonth) then \'xs:gMonth\' else if (. instance of xs:gMonthDay) then \'xs:gMonthDay\' else if (. instance of xs:gDay) then \'xs:gDay\' else if (. instance of xs:untypedAtomic) then \'xs:untypedAtomic\' else if (. instance of document-node()) then \'document-node\' else if (. instance of element()) then \'element\' else if (. instance of comment()) then \'comment\' else if (. instance of processing-instruction()) then \'processing-instruction\' else if (. instance of text()) then \'text\' else if (. instance of attribute()) then \'attribute\' else \'node\'}" name="{if (. instance of xs:anyAtomicType) then \'\' else name(.)}" path="{if (. instance of xs:anyAtomicType) then () else f:pathlocation(.)}"> <xsl:value-of select="."/> </result> </xsl:for-each> </xsl:template>  <xsl:function name="f:pathlocation"> <xsl:param name="node"/> <xsl:value-of select="string-join(reverse(f:getpath($node)),\'/\')"/> </xsl:function>  <xsl:function name="f:getpath"> <xsl:param name="node"/> <xsl:for-each select="$node"> <xsl:variable name="n" select="."/> <xsl:value-of select="if ($node instance of element()) then     for $c in count(preceding-sibling::*[name(.) eq name($n)]) return     if ($c gt 0 or count(following-sibling::*[name(.) eq name($n)]) gt 0) then concat(name(.), \'[\',$c + 1,\']\') else name($n) else if ($node instance of attribute()) then     concat(\'@\',name($n)) else if ($node instance of text()) then     for $t in count(preceding-sibling::text()) return     if ($t gt 0 or count(following-sibling::text()) gt 0) then concat(\'text()[\', $t + 1, \']\') else \'text()\' else if ($node instance of comment()) then     for $ct in count(preceding-sibling::comment()) return     if ($ct gt 0 or count(following-sibling::comment) gt 0) then concat(\'comment()[\', $ct + 1, \']\') else \'comment()\' else if ($node instance of processing-instruction()) then     for $pi in count(preceding-sibling::processing-instruction()) return     if ($pi gt 0 or count(following-sibling::processing-instruction()) gt 0) then concat(\'processing-instruction()[\', $pi + 1, \']\') else \'processing-instruction()\' else ()"/> <xsl:for-each select="$node/parent::*"> <xsl:sequence select="f:getpath($node/parent::*)"/> </xsl:for-each> </xsl:for-each> </xsl:function>  </xsl:transform>';
   var xsldoc = Saxon.parseXML(xslTextNew);
    try {
        var procResult = Saxon.newXSLT20Processor(xsldoc);
       return procResult.transformToDocument(xmldoc);
       window.alert('failaftertransform');
   } catch(e){
        window.alert("catch");
   }
};

var hexToDecimal = function(hexStringValue){
    return parseInt(hexStringValue, 16);
}

var repNbsp = function(text){
    var result = text.replace(/\xa0/g, " ");
    return result;
}

var getXmlns = function (inDoc) {
    var str = "";
    var def = "";
    var docElement = null;
    for (var e = 0; e < inDoc.childNodes.length; e++) {
        var n = inDoc.childNodes[e];
        if (n.nodeType == 1) {
            docElement = n;
            break;
        }
    }
    var attrs = docElement.attributes;
    for (var i = 0; i< attrs.length; i++) {
        var aName = attrs.item(i).nodeName;
        if (aName.length < 5) { continue; }
        var pre = aName.substring(0, 5);
        if (pre != "xmlns") { continue; }

        if (!(aName == "xmlns:xsl" || aName == "xmlns:xs")) {
            str += (attrs.item(i).nodeName + '="' + attrs.item(i).nodeValue + '" ');
        }
        if (aName.length == 5) {
            def = 'xpath-default-namespace="' + attrs.item(i).nodeValue + '" ';
        }
    }
    var returnObj = {
        str: str,
        def: def
 }
 return returnObj;

};

var clearXmlSource = function () {
    var sourceDiv = document.getElementById("source");
    sourceDiv.innerHTML = "";
}

var makeTemplateCall = function(inDefault, inXmlns, inContext, inVariables, inExpression) {
    var prewrap = '<xsl:for-each ' + inDefault + ' ' + inXmlns + ' select="' + inContext + '"> <wrap>'; // INCONTEXT = '/'

    var allVariables = '';
    for (var i = 0; i < inVariables.length; i++) {
        var inVariable = inVariables[i];
        var preVar = '<xsl:variable name="' + inVariable.vname; // VNAME
        var midVar = preVar + '" select="' + inVariable.vselect; // VSELECT
        var postVar = midVar + '"/>';
        allVariables += postVar;
    }
    var preCall = prewrap + allVariables;
    var inCall = preCall + '<xsl:call-template name="wrap"> <xsl:with-param name="c" select="' + inExpression;  //EXPRESSION';
    return inCall + '"/> </xsl:call-template> </wrap> </xsl:for-each>';
}

var errorCount = 0;

var eh = function (err) {
    var lastErr = (err.message.substring(err.message.length - 9) == "detected.");
    if (err.level == 'SEVERE' && !(lastErr)) {
        errorCount++;
        /*
        var tb = document.getElementById("tbody");
        var pos = err.message.indexOf("XPST");
        var msg = (pos > 0) ? err.message.substring(pos) : err.message;
        tb.innerHTML = "<tr><td>1</td><td>[Error]</td><td></td><td>" + msg + "</td></tr>";
        */
        var msg;
        

        if (err.message.indexOf('JS error in Saxon.parseXML') > -1) {
            // parse error from GWT provides no extra info
        } else {
            var pos = err.message.indexOf("XPST");
            msg = (pos > 0) ? err.message.substring(pos) : err.message;
            writeToAppConsole("<p><span class='console-error'>[Error]</span><br>" + msg + "</p>");
        }
    } else if (err.level == 'INFO' && (err.message.substring(0, 13) == "SaxonCE.Trace")) {
        writeToAppConsole("<p>" + err.message.substring(33) + "</p>");
    }
}

var consoleDiv = document.getElementById("xbody");
var writeToAppConsole = function(htmlText){
    consoleDiv.innerHTML = consoleDiv.innerHTML + htmlText;
}

var cacheRow;
var drScroll = false;

var disableResultScroll = function () {
    isResultsTabFocused = true;
    isXPathEditorFocused = false;
    drScroll = true;
}
var enableResultScroll = function () {
    drScroll = false;
}

var swapRow = function (inRow) {
    //window.alert("swaprow - scrolldisabled: " + drScroll.toString();
    if ((inRow) && !(drScroll)) {
        inRow.scrollIntoView(true);
    }
    var temp = cacheRow;
    cacheRow = inRow;
    return temp;
}
var currentRow = function () {
    return cacheRow;
}
var resetCurrentRow = function () {
    cacheRow = null;
}
var isResultsTabFocused = true;
var isXPathEditorFocused = false;

var getIsResultsFocused = function () {
    return isResultsTabFocused;
}
var getIsXPathEditorFocused = function () {
    return isXPathEditorFocused;
}
var setIsXPathEditorFocused = function () {
    isXPathEditorFocused = true;
}

var getHotRow = function () {
    return cacheRow;
}

var cachePaths = new Array();
var setPaths = function(inPaths){
    cachePaths = inPaths;
}

var getPath = function (index) {
    return cachePaths[index];
}

var getMatchingPathIndex = function (path) {

    for (var i = -1; i < cachePaths.length; i++){
        if (path == cachePaths[i]) {
            return i;
        }
    }
    return -1;
}