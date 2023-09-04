<template>
    <div class="loader">
        <div class="inner"></div>
    </div>
</template>

<script setup></script>

<style scoped>
.loader {
    animation: spin 1.5s linear alternate infinite;
    background: rgb(112, 16, 18);
    border-radius: 50%;
    height: 120px;
    width: 120px;
}

.loader:before {
    background: rgb(112, 16, 18);
    border-radius: 50%;
    content: '';
    display: block;
    height: 0.5em;
    width: 0.5em;
    z-index: 2;
}

.loader:after {
    background: rgb(18, 18, 18);
    border-radius: 50%;
    box-shadow: 0em -2.6em rgb(18, 18, 18), 2.25em -4.02em rgb(18, 18, 18),
        2.25em -1.25em rgb(18, 18, 18), 4.6em 0em rgb(18, 18, 18),
        2.25em 1.25em rgb(18, 18, 18), 2.25em 4.02em rgb(18, 18, 18),
        0em 2.6em rgb(18, 18, 18), -2.25em 4.02em rgb(18, 18, 18),
        -2.25em 1.25em rgb(18, 18, 18), -4.6em 0em rgb(18, 18, 18),
        -2.25em -1.25em rgb(18, 18, 18), -2.25em -4.02em rgb(18, 18, 18);
    content: '';
    display: block;
    height: 2em;
    width: 2em;
}

.inner {
    animation: load 1.5s linear alternate infinite;
    border: solid 1px rgb(112, 16, 18);
    border-radius: 50%;
    height: 1.75em;
    width: 1.75em;
    z-index: 1;
}

.loader,
.loader:before,
.loader:after,
.inner {
    bottom: 0;
    left: 0;
    margin: auto;
    position: absolute;
    right: 0;
    top: 0;
}

@keyframes load {
    0% {
        box-shadow: 0em -2.6em rgb(18, 18, 18), 2.25em -1.25em rgb(18, 18, 18),
            2.25em 1.25em rgb(18, 18, 18), 0em 2.6em rgb(18, 18, 18),
            -2.25em 1.25em rgb(18, 18, 18), -2.25em -1.25em rgb(18, 18, 18);
    }
    15% {
        box-shadow: 0em -2.6em rgb(18, 18, 18), 2.25em -1.25em rgb(18, 18, 18),
            2.25em 1.25em rgb(18, 18, 18), 0em 2.6em rgb(18, 18, 18),
            -2.25em 1.25em rgb(18, 18, 18), -2.25em -1.25em rgb(112, 16, 18);
    }
    30% {
        box-shadow: 0em -2.6em rgb(18, 18, 18), 2.25em -1.25em rgb(18, 18, 18),
            2.25em 1.25em rgb(18, 18, 18), 0em 2.6em rgb(18, 18, 18),
            -2.25em 1.25em rgb(112, 16, 18), -2.25em -1.25em rgb(112, 16, 18);
    }
    45% {
        box-shadow: 0em -2.6em rgb(18, 18, 18), 2.25em -1.25em rgb(18, 18, 18),
            2.25em 1.25em rgb(18, 18, 18), 0em 2.6em rgb(112, 16, 18),
            -2.25em 1.25em rgb(112, 16, 18), -2.25em -1.25em rgb(112, 16, 18);
    }
    60% {
        box-shadow: 0em -2.6em rgb(18, 18, 18), 2.25em -1.25em rgb(18, 18, 18),
            2.25em 1.25em rgb(112, 16, 18), 0em 2.6em rgb(112, 16, 18),
            -2.25em 1.25em rgb(112, 16, 18), -2.25em -1.25em rgb(112, 16, 18);
    }
    75% {
        box-shadow: 0em -2.6em rgb(18, 18, 18), 2.25em -1.25em rgb(112, 16, 18),
            2.25em 1.25em rgb(112, 16, 18), 0em 2.6em rgb(112, 16, 18),
            -2.25em 1.25em rgb(112, 16, 18), -2.25em -1.25em rgb(112, 16, 18);
    }
    90% {
        box-shadow: 0em -2.6em rgb(112, 16, 18), 2.25em -1.25em rgb(112, 16, 18),
            2.25em 1.25em rgb(112, 16, 18), 0em 2.6em rgb(112, 16, 18),
            -2.25em 1.25em rgb(112, 16, 18), -2.25em -1.25em rgb(112, 16, 18);
    }
    100% {
        box-shadow: 0em -2.6em rgb(112, 16, 18), 2.25em -1.25em rgb(112, 16, 18),
            2.25em 1.25em rgb(112, 16, 18), 0em 2.6em rgb(112, 16, 18),
            -2.25em 1.25em rgb(112, 16, 18), -2.25em -1.25em rgb(112, 16, 18);
    }
}

@keyframes spin {
    0% {
        transform: rotate(0deg);
    }
    15% {
        transform: rotate(60deg);
    }
    30% {
        transform: rotate(120deg);
    }
    45% {
        transform: rotate(180deg);
    }
    60% {
        transform: rotate(240deg);
    }
    75% {
        transform: rotate(300deg);
    }
    90% {
        transform: rotate(360deg);
    }
    100% {
        transform: rotate(0deg);
    }
}
</style>
