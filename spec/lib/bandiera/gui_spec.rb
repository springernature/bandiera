require 'spec_helper'
require 'capybara/dsl'

describe Bandiera::GUI do
  include Capybara::DSL

  let(:service) { Bandiera::FeatureService.new }

  before do
    Capybara.app = Bandiera::GUI.new

    service.add_features([
      { group: 'pubserv',   name: 'show_subjects',  description: 'Show all subject related features', active: false },
      { group: 'pubserv',   name: 'show_search',    description: 'Show the search bar',               active: true  },
      { group: 'laserwolf', name: 'enable_caching', description: 'Enable caching',                    active: false },
      { group: 'shunter',   name: 'stats_logging',  description: 'Log stats',                         active: true  }
    ])
  end

  def check_success_flash(expected_text)
    expect(page).to have_selector('.alert-success')
    expect(page.find('.alert-success')).to have_content(expected_text)
  end

  def check_error_flash(expected_text)
    expect(page).to have_selector('.alert-danger')
    expect(page.find('.alert-danger')).to have_content(expected_text)
  end

  describe 'the homepage' do
    it 'shows all feature flags organised by group' do
      visit('/')

      groups = {}

      all('.bandiera-feature-group').each do |div|
        group_name = div.find('h3').text
        features   = div.all('tr.bandiera-feature').map do |tr|
          tr.all('td')[2].text
        end

        groups[group_name] = features
      end

      expect(groups['pubserv']).to match_array(%w(show_subjects show_search))
      expect(groups['laserwolf']).to match_array(['enable_caching'])
      expect(groups['shunter']).to match_array(['stats_logging'])
    end
  end

  describe 'adding a new group' do
    before do
      visit('/new/group')
    end

    context 'with a valid group name' do
      it 'adds a new group' do
        within('form') do
          fill_in 'group_name', with: 'TEST'
          click_button 'Create'
        end

        check_success_flash('Group created')
        expect(service.get_groups).to include('TEST')
      end
    end

    context 'with a blank group name' do
      it 'shows validation errors' do
        within('form') do
          fill_in 'group_name', with: ''
          click_button 'Create'
        end

        check_error_flash('You must enter a group name')
      end
    end
  end

  describe 'adding a new feature flag' do
    before do
      visit('/new/feature')
    end

    context 'with valid details' do
      it 'adds a new feature flag' do
        within('form') do
          select 'pubserv', from: 'feature_group'
          fill_in 'feature_name', with: 'TEST-FEATURE'
          fill_in 'feature_description', with: 'This is a test feature.'
          choose 'feature_active_true'
          click_button 'Create'
        end

        check_success_flash('Feature created')
        expect(service.get_feature('pubserv', 'TEST-FEATURE')).to be_an_instance_of(Bandiera::Feature)
      end

      context 'for a feature flag configured for user_groups' do
        it 'adds the feature flag' do
          within('form') do
            select 'pubserv', from: 'feature_group'
            fill_in 'feature_name', with: 'TEST-FEATURE'
            fill_in 'feature_description', with: 'This is a test feature.'
            choose 'feature_active_true'
            fill_in 'feature_user_groups_list', with: "Editor\nWriter"
            fill_in 'feature_user_groups_regex', with: '.*Admin'
            click_button 'Create'
          end

          check_success_flash('Feature created')

          feature = service.get_feature('pubserv', 'TEST-FEATURE')

          expect(feature).to be_an_instance_of(Bandiera::Feature)
          expect(feature.user_groups_configured?).to be_true
          expect(feature.user_groups_list).to eq(%w(Editor Writer))
          expect(feature.user_groups_regex).to eq('.*Admin')
        end
      end
    end

    context 'without selecting a group' do
      it 'shows validation errors' do
        within('form') do
          select '', from: 'feature_group'
          fill_in 'feature_name', with: 'TEST-FEATURE'
          fill_in 'feature_description', with: 'This is a test feature.'
          choose 'feature_active_true'
          click_button 'Create'
        end

        check_error_flash('You must select a group')
      end
    end

    context 'with a blank feature flag name' do
      it 'shows validation errors' do
        within('form') do
          select 'pubserv', from: 'feature_group'
          fill_in 'feature_name', with: ''
          fill_in 'feature_description', with: 'This is a test feature.'
          choose 'feature_active_true'
          click_button 'Create'
        end

        check_error_flash('You must enter a feature name')
      end
    end

    context 'with a feature flag name containing a space' do
      it 'shows validation errors' do
        within('form') do
          select 'pubserv', from: 'feature_group'
          fill_in 'feature_name', with: 'show something'
          fill_in 'feature_description', with: 'This is a test feature.'
          choose 'feature_active_true'
          click_button 'Create'
        end

        check_error_flash('You must enter a feature name without spaces')
      end
    end
  end

  describe 'editing a feature flag' do
    before do
      visit('/')

      row           = first('tr.bandiera-feature')
      @feature_name = row.all('td')[2].text

      row.find('.bandiera-edit-feature').click
    end

    context 'updating the group' do
      context 'setting it as blank' do
        it 'shows validation errors' do
          within('form') do
            select '', from: 'feature_group'
            click_button 'Update'
          end

          check_error_flash('You must select a group')
        end
      end

      context 'choosing another group' do
        it 'moves the feature to the new group' do
          curr_group    = find_field('feature_group').value
          other_groups  = service.get_groups - [curr_group]
          new_group     = other_groups.sample

          within('form') do
            select new_group, from: 'feature_group'
            click_button 'Update'
          end

          expect(service.get_feature(new_group, @feature_name)).to be_an_instance_of(Bandiera::Feature)
        end
      end
    end

    context 'updating the name' do
      context 'setting it as something invalid' do
        it 'shows validation errors' do
          within('form') do
            fill_in 'feature_name', with: 'bob flemming'
            click_button 'Update'
          end

          check_error_flash('You must enter a feature name without spaces')
        end
      end

      context 'with a new valid name' do
        it 'updates the feature flag' do
          find_field('feature_group').select('laserwolf')

          within('form') do
            fill_in 'feature_name', with: 'bob-flemming'
            click_button 'Update'
          end

          check_success_flash('Feature updated')
          expect(service.get_feature('laserwolf', 'bob-flemming')).to be_an_instance_of(Bandiera::Feature)
        end
      end
    end
  end

  describe 'removing a feature flag' do
    it 'deletes a flag' do
      visit('/')

      group_div    = first('.bandiera-feature-group')
      group_name   = group_div.find('h3').text
      feature_row  = group_div.first('tr.bandiera-feature')
      feature_name = feature_row.first('td').text

      feature_row.find('.bandiera-delete-feature').click

      check_success_flash('Feature deleted')
      expect { service.get_feature(group_name, feature_name) }.to raise_error
    end
  end
end
