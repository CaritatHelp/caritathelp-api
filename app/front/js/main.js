
	$('body').scrollspy({ target: '#scrollspy' });

	$('#toggle-menu').click(function(){
		$('.list-group-item').not($(this)).slideToggle();
	});