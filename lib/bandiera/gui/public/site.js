
function insertToggles() {
  $('.feature-toggle').each(function() {
    var checked = '';
    if ($(this).data("active") === true) {
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
    var active       = data.value;

    $.ajax({
      url:     '/update/feature/active_toggle',
      type:    'PUT',
      data:    { feature: { group: group, name: feature_name, active: active } },
      success: function() {},
      error:   function() { alert("Something went wrong..."); location.reload(); }
    });
  });

  insertToggles();

  $('#datetimepicker-start').datetimepicker({format: 'YYYY-MM-DD hh:mm:ss'});
  $('#datetimepicker-end').datetimepicker({format: 'YYYY-MM-DD hh:mm:ss'});
});

