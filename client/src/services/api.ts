import axios from 'axios';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000/api';

const getAuthHeader = () => {
  const token = localStorage.getItem('token');
  return token ? { Authorization: `Bearer ${token}` } : {};
};

export const boardService = {
  getAll: async () => {
    const response = await axios.get(`${API_URL}/boards`, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  getOne: async (id: number) => {
    const response = await axios.get(`${API_URL}/boards/${id}`, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  create: async (data: { title: string; description?: string; background?: string }) => {
    const response = await axios.post(`${API_URL}/boards`, data, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  update: async (id: number, data: { title?: string; description?: string; background?: string }) => {
    const response = await axios.put(`${API_URL}/boards/${id}`, data, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  delete: async (id: number) => {
    const response = await axios.delete(`${API_URL}/boards/${id}`, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  addMember: async (id: number, email: string) => {
    const response = await axios.post(`${API_URL}/boards/${id}/members`, { email }, {
      headers: getAuthHeader()
    });
    return response.data;
  }
};

export const listService = {
  create: async (data: { title: string; boardId: number }) => {
    const response = await axios.post(`${API_URL}/lists`, data, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  update: async (id: number, data: { title?: string; position?: number; color?: string }) => {
    const response = await axios.put(`${API_URL}/lists/${id}`, data, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  delete: async (id: number) => {
    const response = await axios.delete(`${API_URL}/lists/${id}`, {
      headers: getAuthHeader()
    });
    return response.data;
  }
};

export const cardService = {
  create: async (data: { title: string; listId: number; description?: string; dueDate?: string }) => {
    const response = await axios.post(`${API_URL}/cards`, data, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  update: async (id: number, data: { title?: string; description?: string; listId?: number; position?: number; dueDate?: string }) => {
    const response = await axios.put(`${API_URL}/cards/${id}`, data, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  delete: async (id: number) => {
    const response = await axios.delete(`${API_URL}/cards/${id}`, {
      headers: getAuthHeader()
    });
    return response.data;
  }
};

export const labelService = {
  getForBoard: async (boardId: number) => {
    const response = await axios.get(`${API_URL}/labels/board/${boardId}`, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  create: async (data: { name: string; color: string; boardId: number }) => {
    const response = await axios.post(`${API_URL}/labels`, data, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  addToCard: async (cardId: number, labelId: number) => {
    const response = await axios.post(`${API_URL}/labels/card/${cardId}`, { labelId }, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  removeFromCard: async (cardId: number, labelId: number) => {
    const response = await axios.delete(`${API_URL}/labels/card/${cardId}/${labelId}`, {
      headers: getAuthHeader()
    });
    return response.data;
  }
};

export const commentService = {
  getForCard: async (cardId: number) => {
    const response = await axios.get(`${API_URL}/comments/card/${cardId}`, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  create: async (data: { content: string; cardId: number }) => {
    const response = await axios.post(`${API_URL}/comments`, data, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  update: async (id: number, content: string) => {
    const response = await axios.put(`${API_URL}/comments/${id}`, { content }, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  delete: async (id: number) => {
    const response = await axios.delete(`${API_URL}/comments/${id}`, {
      headers: getAuthHeader()
    });
    return response.data;
  }
};
