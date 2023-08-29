import axios from 'axios';

const api = axios.create({
    baseURL: `https://${
        typeof GetParentResourceName !== 'undefined'
            ? GetParentResourceName()
            : 'feather-banks'
    }/`,
});

export default api;
