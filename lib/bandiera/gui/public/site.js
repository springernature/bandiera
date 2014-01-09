
$(document).ready(function() {
  $('a[data-method="delete"]').on('click', function(event) {
    if (!confirm("Are you sure?")) {
      event.preventDefault();
    }
  });
});

