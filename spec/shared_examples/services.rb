shared_examples_for 'a feature service' do
  methods = %w[
    add_group
    fetch_groups
    find_group
    add_feature
    add_features
    remove_feature
    update_feature
    fetch_feature
    fetch_group_features
  ]

  methods.each do |method|
    it { is_expected.to respond_to(method) }
  end
end
