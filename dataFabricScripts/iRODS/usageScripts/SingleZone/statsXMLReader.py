import sys
import xml.dom.minidom
import time
#single file reader

class XMLObject(object):
    def __init__(self, _map, _list):
        self.map = _map
        self.resourceList = _list

class StatsXMLReader(object):
    TIMEFMT = '%Y-%m-%dT%H:%M:%S'
    def __init__(self, _fullFilePath):
        self.doc = xml.dom.minidom.parse(_fullFilePath)

    def cleanup(self):
        self.doc.unlink()

    def getFirstTextNode(self, elementName):
        firstElement = self.doc.getElementsByTagName(elementName)[0]
        return firstElement.childNodes[0].nodeValue.strip()

    def getChildText(self, node, childName):
        return node.getElementsByTagName(childName)[0].firstChild.nodeValue.strip()

    def makeList(self, nodeName):
        nodeList = self.doc.getElementsByTagName(nodeName)
        result = []
        for node in nodeList:
            resourceList = []
            map = {}
            for child in node.childNodes:
                if(child.nodeType == child.ELEMENT_NODE):
                    if(child.tagName == "resources"):
                        rsList = child.getElementsByTagName('resource')
                        for rsUse in rsList:
                            id = self.getChildText(rsUse, 'id')
                            amount = self.getChildText(rsUse, 'amount')
                            count = self.getChildText(rsUse, 'count')
                            resourceList.append((id, amount, count))
                    else:
                        map[child.tagName] = child.firstChild.nodeValue.strip()
            res = XMLObject(map, resourceList)
            result.append(res)
        return result

    def getDBObjects(self):
        self.zone = self.getFirstTextNode('zone')
        self.userList = self.makeList('user')
        self.groupList = self.makeList('project')
