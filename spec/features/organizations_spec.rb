require 'rails_helper'
require_relative '../support/validation_helper'

describe 'Organizations' do

  describe '#index' do
    it 'works' do
      visit '/participating-orgs'
      expect(page.status_code).to eq(200)
      expect(page).to have_text('Participating Organizations')
      expect(page).to have_text('WGBH')
      expect(page).to have_text('Boston, Massachusetts')

      expect(page).to have_xpath('//a[@href="/participating-orgs/1784.2"]')

      expect_fuzzy_xml
    end
  end

  describe '#show' do
    it 'works' do
      visit '/participating-orgs/1784.2'
      expect(page.status_code).to eq(200)
      expect(page).to have_text('WGBH')
      expect(page).to have_text('Boston, Massachusetts')
      # TODO: when WGBH has more content, make sure it shows up.

      expect(page).not_to have_text('WGBY')
      # Has ID "1784": We want to be sure Rails is not ignoring the ".2".

      expect(page).to have_xpath('//a[@href="/catalog?f[organization][]=WGBH"]')

      expect_fuzzy_xml
    end
  end

end