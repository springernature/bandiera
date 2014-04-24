
function insertToggles() {
  $('.feature-toggle').each(function() {
    var checked = '';
    if ($(this).data("enabled") === true) {
      checked = 'checked';
    }

    $(this).html('<input class="feature-toggle-input" type="checkbox" ' + checked + '>');
    $(this).find('input').bootstrapSwitch();
  });
}


$(document).ready(function() {
  $('a[data-method="delete"]').on('click', function(event) {
    if (!confirm("Are you sure?")) {
      event.preventDefault();
    }
  });

  $('.bandiera-feature').on('switchChange', '.feature-toggle-input', function(e, data) {
    var parent       = $(this).closest(".feature-toggle");
    var group        = parent.data("group");
    var feature_name = parent.data("feature");
    var description  = parent.data("description");
    var enabled      = data.value;

    $.ajax({
      url:      '/api/v1/groups/' + encodeURIComponent(group) + '/features/' + encodeURIComponent(feature_name),
      type:     'PUT',
      data:     { feature: { group: group, name: feature_name, description: description, enabled: enabled } },
      success:  function() {},
      error:    function() { alert("Something went wrong..."); location.reload(); }
    });
  });

  insertToggles();
});

