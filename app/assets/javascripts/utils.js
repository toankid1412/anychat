// Global setting for toastr
toastr.options.closeButton = true;
toastr.options.timeOut = 30 * 1000;
toastr.options.escapeHtml = true;

Object.size = function(obj){
    var size = 0, key;
    for (key in obj) {
        if (obj.hasOwnProperty(key)) size++;
    }
    return size;
};

$.fn.loading = function(show) {
    if(show){
        console.log('show loading');
    }else{
        console.log('hide loading');
    }
};

$(document).on('click', 'input[type="submit"]',function(e){
    e.preventDefault();
    e.stopPropagation();
    var form = $(this).closest('form');
    var formValid = true;
    $.each(form.find('.required'), function(_, ele){
        var $ele = $(ele);
        if ($ele.val() == ''){
            toastr.error($ele.data('required-msg'));
            formValid = false;
        }
    });
    if(formValid){
        form.submit();
    }
});