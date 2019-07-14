$(document).on('click', '.start', function() {
    var tds = $(this).parent().parent().children().get();
    console.log(tds);
    for (tdx in tds) {
        console.log(tds[tdx]);
        $(tds[tdx].getElementsByTagName('div')[0]).attr('class', 'done');
    }
    $(this).attr('class', $(this).attr('id'));
    if ($(this).attr('id') == 'correct') {
        console.log($('#right').innerHTML);
        $('#right').get(0).value++ ;
    }
    else {
        console.log($('#wrong').innerHTML);
        $('#wrong').get(0).value++ ;
        var correct_div = Number($(this).parent().parent().children().find('#answer').val());
        $(tds[correct_div].getElementsByTagName('div')[0]).attr('class', 'correct');
    }
});

