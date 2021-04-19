from common.utils import deURN, loginfo
import xml.etree.ElementTree as ET
# import sys, csv, re, os
from xml.sax.saxutils import escape
from taxoneditor.lookupMajorGroup import lookupMajorGroup

from xml.etree.ElementTree import fromstring

TITLE = 'Taxon Editor'
numberWanted = 10

# these are constants, some of which need to be kept up to date.

taxon_authority_csid = '87036424-e55f-4e39-bd12'
tropicos_api_key = 'd0a905a9-75c9-466e-bbab-5b568f4e8b91'
termTypeDropdowns = [('descriptor', 'descriptor'), ('Leave empty', '')]
termStatusDropdowns = [('accepted', 'accepted'), ('Leave empty', '')]
taxonRankDropdowns = [('species', 'species'), ('genus', 'genus')]
taxonfields = [
    ('select', '', 'ignore', '', ''),
    ('n', 'N', 'ignore', '', ''),
    ('family', 'Family', 'string', 'taxon_naturalhistory.family', 'taxon'),
    ('majorgroup', 'Major Group', 'dropdown', 'taxon_ucjeps.taxonMajorGroup', 'taxon'),
    ('termDisplayName', 'Scientific Name with Authors', 'string', 'taxon_common.taxonTermGroupList.taxonTermGroup.termDisplayName', 'taxon'),
    ('termName', 'Scientific Name', 'string', 'taxon_common.taxonTermGroupList.taxonTermGroup.termName', 'taxon'),
    ('commonName', 'Common Name', 'string', 'taxon_common.commonNameGroupList.commonNameGroup.commonName', 'common'),
    ('termSource', 'Source', 'string', 'taxon_common.taxonTermGroupList.taxonTermGroup.termSource', 'taxon'),
    ('termSourceID', 'Source ID', 'string', 'taxon_common.taxonTermGroupList.taxonTermGroup.termSourceID', 'taxon'),
    ('updated_at', 'Updated At', 'ignore', '', ''),
    ('inAuthority', 'Authority CSID', 'ignore', '', '')
]

taxontermsources = {
    "COL": "urn:cspace:ucjeps.cspace.berkeley.edu:vocabularies:name(taxontermsource):item:name(taxontermsource05)'Accession sheet'",
    "GBIF": "urn:cspace:ucjeps.cspace.berkeley.edu:vocabularies:name(taxontermsource):item:name(taxontermsource53)'GBIF'",
    # xxx": "urn:cspace:ucjeps.cspace.berkeley.edu:vocabularies:name(taxontermsource):item:name(taxontermsource23)'Index Fungorum'",
    # xxx": "urn:cspace:ucjeps.cspace.berkeley.edu:vocabularies:name(taxontermsource):item:name(taxontermsource24)'Index Herbariorum Index to Collectors'",
    # xxx": "urn:cspace:ucjeps.cspace.berkeley.edu:vocabularies:name(taxontermsource):item:name(taxontermsource25)'Index Kewensis'",
    # xxx": "urn:cspace:ucjeps.cspace.berkeley.edu:vocabularies:name(taxontermsource):item:name(taxontermsource26)'Index Nominum Algarum'",
    # xxx": "urn:cspace:ucjeps.cspace.berkeley.edu:vocabularies:name(taxontermsource):item:name(taxontermsource27)'Index Nominum Genericorum'",
    # xxx": "urn:cspace:ucjeps.cspace.berkeley.edu:vocabularies:name(taxontermsource):item:name(taxontermsource28)'Index to California Plant Names'",
    # xxx": "urn:cspace:ucjeps.cspace.berkeley.edu:vocabularies:name(taxontermsource):item:name(taxontermsource30)'International Plant Names Index'",
    # xxx": "urn:cspace:ucjeps.cspace.berkeley.edu:vocabularies:name(taxontermsource):item:name(taxontermsource39)'Richard L. Moe'",
    # xxx": "urn:cspace:ucjeps.cspace.berkeley.edu:vocabularies:name(taxontermsource):item:name(taxontermsource41)'Royal Botanical Gardens (KEW)'",
    # xxx": "urn:cspace:ucjeps.cspace.berkeley.edu:vocabularies:name(taxontermsource):item:name(taxontermsource46)'The Jepson Manual: Higher Plants of California'",
    # xxx": "urn:cspace:ucjeps.cspace.berkeley.edu:vocabularies:name(taxontermsource):item:name(taxontermsource32)'Jepson Interchange'",
    "Tropicos": "urn:cspace:ucjeps.cspace.berkeley.edu:vocabularies:name(taxontermsource):item:name(taxontermsource49)'Tropicos'",
    # xxx": "urn:cspace:ucjeps.cspace.berkeley.edu:vocabularies:name(taxontermsource):item:name(taxontermsource50)'UC Botanical Garden'",
}

keep_for_now = [
    ('termFormattedDisplayName', 'Formatted Scientific Name', 'string', '', ''),
    ('taxonomicStatus', 'Taxonomic Status', 'string', '', ''),
    ('termPrefForLang', 'Term Language', 'string', '', ''),
    ('termType', 'Term Type', 'dropdown', termTypeDropdowns, '', ''),
    ('termStatus', 'Term Status', 'dropdown', termStatusDropdowns, '', ''),
    ('taxonCurrency', 'Taxon Currency', 'string', '', ''),
    ('taxonRank', 'Rank', 'dropdown', taxonRankDropdowns, 'taxon_common.taxonRank', 'taxonrank')
]


def getDropdowns(name, type):
    if type == 'dropdown':
        if name == 'majorgroup':
            return [(a,a) for a in lookupMajorGroup('allgroups').keys()]
    else:
        return None

# labels = 'n,family,major group,scientific name with authors,scientific name,idsource,id'.split(',')
labels = [n[1] for n in taxonfields]
labels = labels[:10]
formfields = [{'name': f[0], 'label': f[1], 'fieldtype': f[2], 'value': '', 'type': 'text', 'dropdowns': getDropdowns(f[0], f[2])} for f in taxonfields]
# this file should be in the same directory as this module
xmlfile = 'taxon.xml'
try:
    template = open(xmlfile).read()
    templateXML = fromstring(template)
    items = templateXML.findall('.//list-item')
except:
    loginfo('taxoneditor', 'could not open and parse XML template file %s' % xmlfile, {}, {})


def xName(name, fieldname, idx):
    csname = taxonfields[idx + 1][0]
    if fieldname in name:
        if name[fieldname] is not None:
            return [csname, name[fieldname]]
        else:
            return [csname, '']
    else:
        return [csname, '']


def extractTag(xml, tag):
    element = xml.find('.//%s' % tag)
    try:
        if "urn:" in element.text:
            element_text = deURN(str(element.text))
        else:
            element_text = element.text
    except:
        element_text = ''
    return element_text

