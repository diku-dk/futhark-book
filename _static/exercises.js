function toggleVisible (x) {
    if (x.style.display === "block") {
        x.style.display = "none";
    } else {
        x.style.display = "block";
    }
}

window.onload = function () {
    $('.solution:first>.admonition-title').each(function (index) {
        solution = this.nextElementSibling;
        this.onclick = function() { toggleVisible(solution); };
    });
}
