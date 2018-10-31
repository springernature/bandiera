# frozen_string_literal: true

require 'spec_helper'
require 'capybara/dsl'
require 'capybara/rspec'
require 'capybara/poltergeist'

RSpec.describe Bandiera::GUI do
  include Capybara::DSL

  let(:audit_context) { Bandiera::AnonymousAuditContext.new }

  before(:all) do
    app = Bandiera::GUI.new
    Capybara.app = Rack::Builder.new do
      use Macmillan::Utils::StatsdMiddleware, client: Bandiera.statsd
      run app
    end
    @service = app.settings.feature_service
    Capybara.default_driver    = :rack_test
    Capybara.javascript_driver = :poltergeist
  end

  before do
    @service.add_group(audit_context, 'nofeatures_group')
    @service.add_features(audit_context, [
                            { group: 'pubserv',    name: 'show_subjects',  description: 'Show all subject related features', active: false },
                            { group: 'pubserv',    name: 'show_search',    description: 'Show the search bar',               active: true  },
                            { group: 'laserwolf',  name: 'enable_caching', description: 'Enable caching',                    active: false },
                            { group: 'shunter',    name: 'stats_logging',  description: 'Log stats',                         active: true  },
                            { group: 'parliament', name: 'show_search',    description: 'Show search box', active: false }
                          ])
  end

  describe 'health checks' do
    context '/status/live' do
      it 'returns 200, OK' do
        visit('/status/live')
        expect(page.status_code).to eq(200)
        expect(page.body).to eq('OK')
      end
    end

    ['/healthz', '/status/ready'].each do |path|
      context path do
        context 'when all is ok' do
          it 'returns 200, OK' do
            visit(path)
            expect(page.status_code).to eq(200)
            expect(page.body).to eq('OK')
          end
        end

        context 'when there is a problem' do
          before do
            allow(Bandiera::Db).to receive(:ready?).and_return(false)
          end

          it 'returns 500, NOT OK' do
            visit(path)
            expect(page.status_code).to eq(500)
            expect(page.body).to eq('NOT OK')
          end
        end
      end
    end
  end

  describe 'the homepage' do
    it 'shows all feature flags organised by group' do
      visit('/')

      groups = get_groups_with_features

      expect(groups['nofeatures_group']).to match_array([])
      expect(groups['pubserv']).to match_array(%w[show_subjects show_search])
      expect(groups['laserwolf']).to match_array(['enable_caching'])
      expect(groups['shunter']).to match_array(['stats_logging'])
    end

    it 'allows you to toggle the "active" flag on a feature', js: true do
      visit('/')

      toggle_container = first('.feature-toggle')
      toggle           = toggle_container.first('.switch')
      group            = toggle_container[:'data-group']
      name             = toggle_container[:'data-feature']
      active           = toggle_container[:'data-active'] == 'true'
      switch_class     = active ? 'switch-on' : 'switch-off'

      expect(toggle_container).to have_css(".#{switch_class}")
      expect(@service.fetch_feature(group, name).active?).to eq(active)

      toggle.click

      expect(toggle_container).to_not have_css(".#{switch_class}")
      expect(@service.fetch_feature(group, name).active?).to_not eq(active)
    end
  end

  describe 'visiting a group page' do
    context 'when the group does not exist' do
      it 'returns a 404' do
        visit('/groups/nogrouphere')
        expect(page.status_code).to eq(404)
      end
    end

    context 'when the group exists' do
      context 'and has features' do
        it 'shows features of group' do
          visit('/groups/pubserv')
          groups = get_groups_with_features

          expect(groups['pubserv']).to match_array(%w[show_subjects show_search])
          expect(groups.size).to eq(1)
        end
      end

      context 'and doesnt have features' do
        it 'no features are showed' do
          visit('/groups/nofeatures_group')
          groups = get_groups_with_features

          expect(groups.size).to eq(1)
          expect(groups['nofeatures_group']).to match_array([])
          expect(first('p.no-features')).to have_content('There are no features setup...')
        end
      end
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
        expect(@service.fetch_groups.map(&:name)).to include('TEST')
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

    context 'with a space in the group name' do
      it 'shows validation errors' do
        within('form') do
          fill_in 'group_name', with: ' foo'
          click_button 'Create'
        end

        check_error_flash('You must enter a group name without spaces')
      end
    end

    context 'with a tab in the group name' do
      it 'shows validation errors' do
        within('form') do
          fill_in 'group_name', with: "foo\t"
          click_button 'Create'
        end

        check_error_flash('You must enter a group name without spaces')
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
        expect(@service.fetch_feature('pubserv', 'TEST-FEATURE')).to be_an_instance_of(Bandiera::Feature)
        expect(page).to have_current_path('/')
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

          feature = @service.fetch_feature('pubserv', 'TEST-FEATURE')

          expect(feature).to be_an_instance_of(Bandiera::Feature)
          expect(feature.user_groups_configured?).to be_truthy
          expect(feature.user_groups_list).to eq(%w[Editor Writer])
          expect(feature.user_groups_regex).to eq('.*Admin')
        end
      end

      context 'for a feature flag configured with a start and end time' do
        it 'adds the feature flag' do
          within('form') do
            select 'parliament', from: 'feature_group'
            fill_in 'feature_name', with: 'dissolution'
            fill_in 'feature_description', with: 'We are in dissolution.'
            choose 'feature_active_true'
            fill_in 'feature_start_time', with: '2017-05-06 00:25:30'
            fill_in 'feature_end_time', with: '2017-06-08 23:59:59'
            fill_in 'feature_user_groups_regex', with: '.*Admin'
            click_button 'Create'
          end

          check_success_flash('Feature created')

          feature = @service.fetch_feature('parliament', 'dissolution')

          expect(feature).to be_an_instance_of(Bandiera::Feature)
          expect(feature.user_groups_configured?).to be_truthy
          expect(feature.start_time).to eq(Time.new(2017, 5, 6, 0, 25, 30))
          expect(feature.end_time).to eq(Time.new(2017, 6, 8, 23, 59, 59))
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

    context 'with a feature flag name containing a tab' do
      it 'shows validation errors' do
        within('form') do
          select 'pubserv', from: 'feature_group'
          fill_in 'feature_name', with: "TEST-FEATURE\t"
          fill_in 'feature_description', with: 'This is a test feature.'
          choose 'feature_active_true'
          click_button 'Create'
        end

        check_error_flash('You must enter a feature name without spaces')
      end
    end

    context 'with a feature flag that has a start time without an end time' do
      it 'shows validation errors' do
        within('form') do
          select 'pubserv', from: 'feature_group'
          fill_in 'feature_name', with: 'TEST-FEATURE'
          fill_in 'feature_description', with: 'This is a test feature.'
          choose 'feature_active_true'
          fill_in 'feature_start_time', with: '2017-05-06 00:25:30'
          click_button 'Create'
        end

        check_error_flash('You must enter an end time if you enter a start')
      end
    end

    context 'with a feature flag that has an end time without a start time' do
      it 'shows validation errors' do
        within('form') do
          select 'pubserv', from: 'feature_group'
          fill_in 'feature_name', with: 'TEST-FEATURE'
          fill_in 'feature_description', with: 'This is a test feature.'
          choose 'feature_active_true'
          fill_in 'feature_end_time', with: '2017-06-08 23:59:59'
          click_button 'Create'
        end

        check_error_flash('You must enter a start time if you enter an end')
      end
    end

    context 'with a feature flag that has an end time that starts before the start time' do
      it 'shows validation errors' do
        within('form') do
          select 'pubserv', from: 'feature_group'
          fill_in 'feature_name', with: 'TEST-FEATURE'
          fill_in 'feature_description', with: 'This is a test feature.'
          choose 'feature_active_true'
          fill_in 'feature_start_time', with: '2017-06-08 23:59:59'
          fill_in 'feature_end_time', with: '2017-05-06 00:25:30'
          click_button 'Create'
        end

        check_error_flash('You must enter an end time that is after your start time')
      end
    end
  end

  describe 'adding a new feature flag with group query param' do
    before do
      visit('/new/feature?group=shunter')
    end

    context 'with valid details' do
      it 'adds a new feature flag and returns to group page' do
        within('form') do
          fill_in 'feature_name', with: 'TEST-FEATURE'
          fill_in 'feature_description', with: 'This is a test feature.'
          choose 'feature_active_true'
          click_button 'Create'
        end

        check_success_flash('Feature created')
        expect(@service.fetch_feature('shunter', 'TEST-FEATURE')).to be_an_instance_of(Bandiera::Feature)
        expect(page).to have_current_path('/groups/shunter')
      end
    end

    context 'with a blank feature flag name' do
      it 'shows validation errors' do
        within('form') do
          fill_in 'feature_name', with: ''
          fill_in 'feature_description', with: 'This is a test feature.'
          choose 'feature_active_true'
          click_button 'Create'
        end

        check_error_flash('You must enter a feature name')
        expect(page).to have_current_path('/new/feature?group=shunter')
      end
    end
  end

  describe 'removing a feature flag' do
    def click_delete_button
      group_div    = first('.bandiera-feature-group')
      group_name   = group_div.find('h3').text
      feature_row  = group_div.first('tr.bandiera-feature')
      feature_name = feature_row.first('td').text

      feature_row.find('.bandiera-delete-feature').click

      [group_name, feature_name]
    end

    it 'deletes a flag' do
      visit('/')
      group_name, feature_name = click_delete_button

      check_success_flash('Feature deleted')
      expect { @service.fetch_feature(group_name, feature_name) }.to raise_error(Bandiera::FeatureService::FeatureNotFound)
    end

    context 'when on a group page' do
      before do
        @service.add_features(audit_context,
          [{ group: 'acidburn', name: 'force_push', description: 'Enable force push', active: false }]
        )

        page.driver.browser.header('Referer', 'http://example.com/groups/acidburn')
      end

      it 'leaves you on a group page after deletion' do
        visit('/groups/acidburn')
        click_delete_button

        check_success_flash('Feature deleted')
        expect(page).to have_current_path('/groups/acidburn')
      end
    end
  end

  describe 'editing a feature flag' do
    context 'when the group does not exist' do
      it 'returns a 404' do
        visit('/groups/wibble/features/stats_logging/edit')
        expect(page.status_code).to eq(404)
      end
    end

    context 'when the flag does not exist' do
      it 'returns a 404' do
        visit('/groups/shunter/features/wibble/edit')
        expect(page.status_code).to eq(404)
      end
    end
  end

  private

  def check_success_flash(expected_text)
    expect(page).to have_selector('.alert-success')
    expect(page.find('.alert-success')).to have_content(expected_text)
  end

  def check_error_flash(expected_text)
    expect(page).to have_selector('.alert-danger')
    expect(page.find('.alert-danger')).to have_content(expected_text)
  end

  def get_groups_with_features
    groups = {}

    all('.bandiera-feature-group').each do |div|
      group_name = div.find('h3').text
      features   = div.all('tr.bandiera-feature').map do |tr|
        tr.all('td')[4].text
      end

      groups[group_name] = features
    end

    groups
  end
end
