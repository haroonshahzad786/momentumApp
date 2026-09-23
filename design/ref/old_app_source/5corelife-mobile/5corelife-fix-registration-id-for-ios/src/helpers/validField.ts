export const regex = /^(?:[^<>()[\].,;:\s@"]+(\.[^<>()[\].,;:\s@"]+)*|"[^\n"]+")@(?:[^<>()[\].,;:\s@"]+\.)+[^<>()[\]\.,;:\s@"]{2,63}$/i;

export const validForm = (data:
    {
        username: string | any,
        email?: string,
        password?: string,
        password_confirmation?: string
    }
) => {
    const { username, email, password, password_confirmation } = data
    if (!username) {
        return { string: 'Completed the field Username', show: true }
    }

    if (!email) {
        return { string: 'Completed the field Email', show: true }
    }

    if (!regex.test(email)) {
        return { string: 'Enter a valid email address', show: true }
    }

    if (!password) {
        return { string: 'Completed the field Password', show: true }
    }

    if (!password_confirmation) {
        return { string: 'Completed the field Repeat password', show: true }
    }

    if (password_confirmation !== password) {
        return { string: 'Password and Repeat password are not similar', show: true }
    }

    if (password.length < 8 || password.length > 14) {
        return { string: 'Password must have at least 8 characters (max 14)', show: true }
    }

    return { string: '', show: false }
}

export const responseBack = (data: any) => {
    if (data?.email) return { string: data.email[0], show: true }
    if (data?.non_field_errors) return { string: data.non_field_errors[0], string2: data.non_field_errors[1], show: true }
    return { string: '', show: false }
}