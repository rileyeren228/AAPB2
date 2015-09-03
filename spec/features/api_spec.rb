require 'rails_helper'
require_relative '../../lib/aapb'
require_relative '../../scripts/lib/pb_core_ingester'

describe 'API' do

  before(:all) do
    PBCoreIngester.load_fixtures
  end

  describe 'good queries' do
    it 'retrieves individual documents' do
      visit '/api.json?callback=callback&rows=1&q=id:1234&fl=id,title'
      expect(page.status_code).to eq 200
      expect(page).to have_text('callback({ "responseHeader"')
      expect(page).to have_text('"rows": "1"')
      expect(page).to have_text('Gratuitous Explosions')
    end

    it 'supports facets for statistics' do
      visit '/api.json?callback=callback&facet=true&facet.field=year&' + 
        'facet.query[]=year:1988+AND+iowa'
      expect(page.status_code).to eq 200
      expect(page).to have_text('callback({ "responseHeader"')
      expect(page).to have_text('"rows": "0"')
      expect(page).to have_text('"year:1988 AND iowa": 1')
      expect(page).to have_text('"numFound": 24')
      expect(page).to have_text('"1981", 1, "1988", 1, "1990", 1, "2000", 1')
    end
    
    it 'searches documents' do
      visit '/api.json?callback=callback&rows=10&q=iowa'
      expect(page.status_code).to eq 200
      expect(page).to have_text('callback({ "responseHeader"')
      expect(page).to have_text('"numFound": 3')
      expect(page).to have_text('Norman Borlaug')
      expect(page.source).to match('"xml": "<pbcoreDescriptionDocument')
      # have_text runs the source through a regex that removes "tags",
      # even in non-xml documents.
    end
    
    it 'supports xml, too' do
      visit '/api.xml?rows=10&q=iowa'
      expect(page.status_code).to eq 200
      expect(page.source).to match('<numFound type="integer">3</numFound>')
      expect(page.source).to match('Norman Borlaug')
      expect(page.source).to match('<xml>&lt;pbcoreDescriptionDocument')
    end
  end
  
  describe 'error handling' do
    it 'has helpful error messages in json' do
      visit '/api.json?facet=error'
      expect(page.status_code).to eq 500
      expect(page).to have_text('"msg": "invalid boolean value: error"')
    end
    
    it 'has helpful error messages in xml' do
      visit '/api.xml?facet=error'
      expect(page.status_code).to eq 500
      expect(page.source).to match('<msg>invalid boolean value: error</msg>')
    end
  end
end
