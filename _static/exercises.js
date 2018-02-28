function toggleVisible (x) {
    if (x.style.display === "none") {
        x.style.display = "block";
    } else {
        x.style.display = "none";
    }
}

window.onload = function () {
    $('.solution>.first').each(function (index) {
        solution = this.nextElementSibling;
        this.onclick = function() { toggleVisible(solution); };
    });
}
